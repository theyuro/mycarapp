import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import '../models/subscription_entitlement.dart';
import 'analytics_service.dart';
import '../l10n/l10n.dart';

class SubscriptionOption {
  const SubscriptionOption({
    required this.product,
    required this.basePlanId,
    required this.billingPeriod,
    required this.price,
    required this.renewalPrice,
    required this.priceMicros,
    required this.renewalMicros,
    required this.currencyCode,
    required this.offerTags,
    this.offerId,
    this.hasFreeTrial = false,
  });

  final ProductDetails product;
  final String basePlanId;
  final String billingPeriod;
  final String price;
  final String renewalPrice;
  final String? offerId;
  final List<String> offerTags;

  /// Preço atual e preço de renovação em micros (1/1.000.000 da unidade da
  /// moeda), para calcular o equivalente mensal e a economia sem depender do
  /// texto já formatado pela Play.
  final int priceMicros;
  final int renewalMicros;

  /// Moeda devolvida pela Google Play para este plano (ex.: "BRL").
  final String currencyCode;

  /// Primeira fase de preço gratuita (oferta de teste grátis da Play).
  final bool hasFreeTrial;

  bool get isAnnual => billingPeriod == 'P1Y';
  bool get isPromotional => offerId != null;

  /// Desconto da primeira fase sobre a renovação, calculado dos micros da
  /// Play (ex.: oferta de saída). `null` sem desconto ou sem preço.
  int? get discountPercent {
    if (renewalMicros <= 0 || priceMicros >= renewalMicros) return null;
    final percent = ((1 - priceMicros / renewalMicros) * 100).round();
    return percent > 0 ? percent : null;
  }
  String get title => isAnnual ? tr.planAnnual : tr.planMonthly;

  String get priceDescription {
    final renewal = isAnnual
        ? tr.perYear(renewalPrice)
        : tr.perMonth(renewalPrice);
    if (isPromotional && price != renewalPrice) {
      return tr.priceOfferThen(price, renewal);
    }
    return renewal;
  }
}

class AccessService extends ChangeNotifier {
  AccessService._();

  static final AccessService instance = AccessService._();
  static const subscriptionProductId = 'mycarapp_subscription';

  /// Modo gratuito: quando `true`, o app é 100% gratuito, com todos os
  /// recursos liberados e monetização apenas por anúncios (AdMob). A cobrança
  /// (Google Play, ofertas, restauração de compras) fica desligada, mas o
  /// código permanece aqui, dormente, para ser reativado trocando para `true`.
  static const freeModeEnabled = false;

  final InAppPurchase _store = InAppPurchase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'southamerica-east1',
  );

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _entitlementSubscription;

  /// Restauração pedida pelo botão; a automática da abertura não gera
  /// evento.
  bool _restoreRequested = false;

  /// Prazo para considerar "nada a restaurar" quando o botão é usado.
  Timer? _restoreTimeout;
  bool _subscriptionActive = false;
  bool _betaPremiumActive = DateTime.now().isBefore(DateTime(2026, 8, 31));
  String? _boundUid;
  List<ProductDetails> _storeProducts = const [];
  Set<String> _allowedOfferTags = const {};
  SubscriptionEntitlement entitlement =
      const SubscriptionEntitlement.inactive();
  DateTime? premiumFreeUntil = DateTime(2026, 8, 31);

  /// Opção em processo de compra, para os eventos do funil (Analytics).
  SubscriptionOption? _purchaseOption;

  /// Build mínimo aceito pelo servidor (ver UpdateService); `null` enquanto
  /// não consultado.
  int? minimumBuild;
  bool _initialized = false;
  bool storeAvailable = false;
  bool loadingStore = true;
  bool purchasePending = false;
  List<SubscriptionOption> subscriptionOptions = const [];
  SubscriptionOption? selectedSubscription;
  String? storeMessage;

  bool get subscriptionActive => _subscriptionActive || _betaPremiumActive;

  /// Recursos Premium liberados: assinante ou app em modo gratuito. O plano
  /// gratuito tem todos os recursos do app; o Premium remove os anúncios e
  /// inclui o backup automático em nuvem.
  bool get premiumUnlocked => freeModeEnabled || subscriptionActive;

  /// Anúncios e convites para assinar aparecem só para quem não é Premium.
  bool get showsAds => freeModeEnabled || !subscriptionActive;

  /// Backup automático em nuvem: só para assinantes (no modo gratuito não há
  /// cobrança, então também não há nuvem).
  bool get cloudBackupEnabled => subscriptionActive;
  bool get paidSubscriptionActive => _subscriptionActive;
  bool get betaPremiumActive => _betaPremiumActive;
  bool get signedIn => _auth.currentUser != null;
  ProductDetails? get subscriptionProduct => selectedSubscription?.product;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _purchaseSubscription = _store.purchaseStream.listen(
      _handlePurchases,
      onError: (Object error) {
        purchasePending = false;
        storeMessage = tr.storeCommError;
        // Erro no stream durante uma restauração pedida pelo botão:
        // finaliza o pedido para não aguardar o prazo de 15s.
        if (_restoreRequested) _finishRequestedRestore('error');
        notifyListeners();
      },
    );
    _authSubscription = _auth.authStateChanges().listen(
      (user) => unawaited(_bindUser(user)),
    );
    await _bindUser(_auth.currentUser);
    unawaited(_loadRemoteAccess());
    if (freeModeEnabled) return;
    unawaited(_connectStore());
  }

  Future<void> _bindUser(User? user) async {
    if (_boundUid == user?.uid && _entitlementSubscription != null) return;
    await _entitlementSubscription?.cancel();
    _entitlementSubscription = null;
    _boundUid = user?.uid;
    _subscriptionActive = false;
    entitlement = const SubscriptionEntitlement.inactive();
    _allowedOfferTags = const {};
    _refreshSubscriptionOptions();
    notifyListeners();

    if (user == null) return;
    _entitlementSubscription = _firestore
        .collection('entitlements')
        .doc(user.uid)
        .snapshots()
        .listen(
          (snapshot) {
            entitlement = snapshot.exists
                ? SubscriptionEntitlement.fromJson(snapshot.data()!)
                : const SubscriptionEntitlement.inactive();
            _subscriptionActive = entitlement.active;
            notifyListeners();
          },
          onError: (Object error) {
            debugPrint('Não foi possível acompanhar a assinatura: $error');
          },
        );
    if (freeModeEnabled) return;
    await _loadPromotionEligibility();
    // Mudança de usuário dispara uma restauração automática; não deve
    // consumir um pedido pendente do botão.
    _finishRequestedRestore(null);
    if (storeAvailable) await _store.restorePurchases();
  }

  Future<void> _loadPromotionEligibility() async {
    if (_auth.currentUser == null) return;
    try {
      final result = await _functions
          .httpsCallable('getPromotionEligibility')
          .call();
      final data = Map<String, dynamic>.from(result.data as Map);
      _allowedOfferTags = (data['availableOfferTags'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toSet();
      _refreshSubscriptionOptions(
        preferredOfferTag: data['bestOfferTag'] as String?,
      );
      notifyListeners();
    } on Object catch (error) {
      debugPrint('Não foi possível consultar ofertas da assinatura: $error');
    }
  }

  Future<void> _loadRemoteAccess() async {
    try {
      final result = await _functions.httpsCallable('getAppAccess').call();
      final data = Map<String, dynamic>.from(result.data as Map);
      final until = DateTime.tryParse(
        data['premiumFreeUntil'] as String? ?? '',
      );
      premiumFreeUntil = until?.toLocal();
      _betaPremiumActive = data['freePremiumActive'] as bool? ?? false;
      minimumBuild = (data['minimumBuild'] as num?)?.toInt();
      notifyListeners();
    } on Object catch (error) {
      debugPrint('Não foi possível consultar o acesso temporário: $error');
    }
  }

  Future<void> _connectStore() async {
    loadingStore = true;
    notifyListeners();
    try {
      storeAvailable = await _store.isAvailable();
      if (!storeAvailable) {
        storeMessage = tr.storeUnavailable;
        return;
      }
      final response = await _store.queryProductDetails({
        subscriptionProductId,
      });
      if (response.error != null) {
        storeMessage = response.error!.message;
      } else if (response.productDetails.isEmpty) {
        storeMessage = tr.storeProductNotFound;
      } else {
        _storeProducts = response.productDetails;
        _refreshSubscriptionOptions();
        storeMessage = subscriptionOptions.isEmpty ? tr.storeNoPlans : null;
      }
      // Restauração automática da conexão com a loja; não deve consumir um
      // pedido pendente do botão.
      _finishRequestedRestore(null);
      if (_auth.currentUser != null) await _store.restorePurchases();
    } on Object catch (error) {
      debugPrint('Falha ao conectar à Google Play: $error');
      storeMessage = tr.storeAccessError;
    } finally {
      loadingStore = false;
      notifyListeners();
    }
  }

  void _refreshSubscriptionOptions({String? preferredOfferTag}) {
    final options = <SubscriptionOption>[];
    for (final product in _storeProducts) {
      if (product is! GooglePlayProductDetails ||
          product.subscriptionIndex == null) {
        options.add(
          SubscriptionOption(
            product: product,
            basePlanId: product.id,
            billingPeriod: '',
            price: product.price,
            renewalPrice: product.price,
            priceMicros: (product.rawPrice * 1000000).round(),
            renewalMicros: (product.rawPrice * 1000000).round(),
            currencyCode: product.currencyCode,
            offerTags: const [],
          ),
        );
        continue;
      }
      final details = product
          .productDetails
          .subscriptionOfferDetails![product.subscriptionIndex!];
      final authorized =
          details.offerId == null ||
          details.offerTags.any(_allowedOfferTags.contains);
      if (!authorized || details.pricingPhases.isEmpty) continue;
      final firstPhase = details.pricingPhases.first;
      final renewalPhase = details.pricingPhases.last;
      options.add(
        SubscriptionOption(
          product: product,
          basePlanId: details.basePlanId,
          billingPeriod: renewalPhase.billingPeriod,
          price: firstPhase.formattedPrice,
          renewalPrice: renewalPhase.formattedPrice,
          priceMicros: firstPhase.priceAmountMicros,
          renewalMicros: renewalPhase.priceAmountMicros,
          currencyCode: renewalPhase.priceCurrencyCode,
          offerId: details.offerId,
          offerTags: List.unmodifiable(details.offerTags),
          hasFreeTrial: firstPhase.priceAmountMicros == 0,
        ),
      );
    }
    options.sort((a, b) {
      final period = _periodOrder(
        a.billingPeriod,
      ).compareTo(_periodOrder(b.billingPeriod));
      if (period != 0) return period;
      return a.isPromotional == b.isPromotional
          ? 0
          : (a.isPromotional ? -1 : 1);
    });
    subscriptionOptions = List.unmodifiable(options);

    final previous = selectedSubscription;
    selectedSubscription = _firstWhereOrNull(
      options,
      (option) =>
          preferredOfferTag != null &&
          option.offerTags.contains(preferredOfferTag),
    );
    selectedSubscription ??= _firstWhereOrNull(
      options,
      (option) =>
          previous != null &&
          option.basePlanId == previous.basePlanId &&
          option.offerId == previous.offerId,
    );
    // Sem oferta preferida nem seleção anterior: pré-seleciona o anual sem
    // oferta (plano padrão sugerido ao usuário).
    selectedSubscription ??= _firstWhereOrNull(
      options,
      (option) => option.isAnnual && !option.isPromotional,
    );
    selectedSubscription ??= _firstWhereOrNull(
      options,
      (option) => !option.isPromotional,
    );
    selectedSubscription ??= options.isEmpty ? null : options.first;
  }

  int _periodOrder(String period) => switch (period) {
    'P1M' => 0,
    'P1Y' => 1,
    _ => 2,
  };

  SubscriptionOption? _firstWhereOrNull(
    List<SubscriptionOption> values,
    bool Function(SubscriptionOption) predicate,
  ) {
    for (final value in values) {
      if (predicate(value)) return value;
    }
    return null;
  }

  void selectSubscription(SubscriptionOption option) {
    if (!subscriptionOptions.contains(option)) return;
    selectedSubscription = option;
    notifyListeners();
  }

  Future<void> refreshSubscriptionOffers() => _loadPromotionEligibility();

  /// Tag da oferta de saída na Play (60% no 1º ano do anual), liberada pelo
  /// servidor só durante a janela concedida por [claimExitOffer].
  static const exitOfferTag = 'exitlag';

  /// Opção da oferta de saída, quando a Play a devolveu e o servidor a
  /// autorizou (dentro da janela de 10 minutos).
  SubscriptionOption? get exitOfferOption => _firstWhereOrNull(
    subscriptionOptions,
    (option) => option.offerTags.contains(exitOfferTag),
  );

  /// Pede ao servidor a oferta de saída (uma única vez por conta). Devolve o
  /// fim da janela informado pelo servidor, ou `null` quando negada, sem
  /// login ou em caso de erro.
  Future<DateTime?> claimExitOffer() async {
    if (_auth.currentUser == null) return null;
    try {
      final result = await _functions.httpsCallable('claimExitOffer').call();
      final data = Map<String, dynamic>.from(result.data as Map);
      if (data['granted'] != true) return null;
      return DateTime.tryParse(data['expiresAt'] as String? ?? '')?.toLocal();
    } on Object catch (error) {
      debugPrint('Não foi possível pedir a oferta de saída: $error');
      return null;
    }
  }

  Future<void> buySubscription() async {
    final user = _auth.currentUser;
    final option = selectedSubscription;
    if (user == null) {
      storeMessage = tr.storeSignInToSubscribe;
      notifyListeners();
      return;
    }
    if (option == null || purchasePending) return;
    purchasePending = true;
    storeMessage = null;
    notifyListeners();
    _purchaseOption = option;
    try {
      final started = await _store.buyNonConsumable(
        purchaseParam: PurchaseParam(
          productDetails: option.product,
          applicationUserName: user.uid,
        ),
      );
      if (started) {
        // Abriu a tela de pagamento da Google Play.
        AnalyticsService.event('purchase_start', {'plan': option.basePlanId});
      } else {
        purchasePending = false;
        storeMessage = tr.storePurchaseNotStarted;
        AnalyticsService.event('purchase_error', {
          'plan': option.basePlanId,
          'result': 'not_started',
        });
        _purchaseOption = null;
        notifyListeners();
      }
    } on Object catch (error) {
      debugPrint('Falha ao iniciar assinatura: $error');
      purchasePending = false;
      storeMessage = tr.storePurchaseStartError;
      AnalyticsService.event('purchase_error', {
        'plan': option.basePlanId,
        'result': 'start_failed',
      });
      _purchaseOption = null;
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    if (_auth.currentUser == null) {
      storeMessage = tr.storeSignInToRestore;
      AnalyticsService.event('purchase_restore', {'result': 'not_signed_in'});
      notifyListeners();
      return;
    }
    if (!storeAvailable || purchasePending) return;
    purchasePending = true;
    storeMessage = tr.storeSearching;
    notifyListeners();
    try {
      _restoreRequested = true;
      // Se a loja não devolver nenhuma compra, considera "nada a
      // restaurar" depois desse prazo.
      _restoreTimeout?.cancel();
      _restoreTimeout = Timer(const Duration(seconds: 15), () {
        if (_restoreRequested) _finishRequestedRestore('not_found');
      });
      await _store.restorePurchases();
      storeMessage = _subscriptionActive
          ? tr.storeRestored
          : tr.storeValidatingRestore;
    } on Object catch (error) {
      debugPrint('Falha ao restaurar assinatura: $error');
      storeMessage = tr.storeRestoreError;
      _finishRequestedRestore('error');
    } finally {
      purchasePending = false;
      notifyListeners();
    }
  }

  /// Finaliza um pedido de restauração feito pelo botão: cancela o prazo de
  /// espera, zera a flag e, quando [result] não é nulo, registra o único
  /// evento `purchase_restore` exigido para esse pedido.
  void _finishRequestedRestore(String? result) {
    _restoreTimeout?.cancel();
    _restoreTimeout = null;
    _restoreRequested = false;
    if (result != null) {
      AnalyticsService.event('purchase_restore', {'result': result});
    }
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != subscriptionProductId) continue;
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // restorePurchases() roda em toda abertura do app: só é uma
          // compra nova quando o status é "purchased".
          final isRequestedRestore =
              purchase.status == PurchaseStatus.restored && _restoreRequested;
          if (isRequestedRestore) {
            // A validação no servidor pode levar mais de 15s; cancela o
            // prazo para não disparar "not_found" enquanto ela corre.
            _restoreTimeout?.cancel();
          }
          await _verifyAndComplete(
            purchase,
            isNewPurchase: purchase.status == PurchaseStatus.purchased,
            isRequestedRestore: isRequestedRestore,
          );
          break;
        case PurchaseStatus.pending:
          purchasePending = true;
          storeMessage = tr.storePending;
          break;
        case PurchaseStatus.error:
          purchasePending = false;
          storeMessage = purchase.error?.message ?? tr.storeNotCompleted;
          if (_restoreRequested) {
            // Erro da loja numa restauração pedida pelo botão: não é uma
            // compra, então não gera evento de funil de compra.
            _finishRequestedRestore('error');
          } else {
            AnalyticsService.event('purchase_error', {
              'plan': _purchaseOption?.basePlanId,
              'result': 'store_error',
            });
            _purchaseOption = null;
          }
          break;
        case PurchaseStatus.canceled:
          purchasePending = false;
          storeMessage = tr.storeCanceled;
          AnalyticsService.event('purchase_cancel', {
            'plan': _purchaseOption?.basePlanId,
          });
          _purchaseOption = null;
          break;
      }
    }
    notifyListeners();
  }

  /// Confirma a compra no servidor. Os eventos do funil só são registrados
  /// para [isNewPurchase]: a restauração roda em toda abertura do app e,
  /// sem essa condição, geraria uma `purchase_complete` falsa a cada vez.
  Future<void> _verifyAndComplete(
    PurchaseDetails purchase, {
    required bool isNewPurchase,
    bool isRequestedRestore = false,
  }) async {
    final option = _purchaseOption;
    final user = _auth.currentUser;
    if (user == null) {
      purchasePending = false;
      storeMessage = tr.storeSameAccount;
      if (isNewPurchase) {
        AnalyticsService.event('purchase_error', {
          'plan': option?.basePlanId,
          'result': 'not_signed_in',
        });
        _purchaseOption = null;
      }
      if (isRequestedRestore) _finishRequestedRestore('error');
      return;
    }
    final token = purchase.verificationData.serverVerificationData.trim();
    if (token.isEmpty) {
      purchasePending = false;
      storeMessage = tr.storeNoVerificationData;
      if (isNewPurchase) {
        AnalyticsService.event('purchase_error', {
          'plan': option?.basePlanId,
          'result': 'no_verification_data',
        });
        _purchaseOption = null;
      }
      if (isRequestedRestore) _finishRequestedRestore('error');
      return;
    }

    purchasePending = true;
    storeMessage = tr.storeValidating;
    notifyListeners();
    try {
      final result = await _functions
          .httpsCallable('verifyAndroidSubscription')
          .call({'purchaseToken': token});
      final data = Map<String, dynamic>.from(result.data as Map);
      entitlement = SubscriptionEntitlement.fromJson(data);
      _subscriptionActive = entitlement.active;
      purchasePending = false;
      storeMessage = entitlement.active ? tr.storeActive : tr.storeNotActive;
      if (entitlement.active && purchase.pendingCompletePurchase) {
        await _store.completePurchase(purchase);
      }
      if (isRequestedRestore) {
        // Só conta a restauração pedida pelo botão, já com a confirmação
        // do servidor.
        _finishRequestedRestore(entitlement.active ? 'restored' : 'not_active');
      }
      if (isNewPurchase) {
        if (entitlement.active) {
          // Só conta como compra concluída com a confirmação do servidor.
          AnalyticsService.event('purchase_complete', {
            'plan': option?.basePlanId,
            'offer_tag': option == null || option.offerTags.isEmpty
                ? null
                : option.offerTags.first,
            'is_trial': option?.hasFreeTrial ?? false,
          });
        } else {
          AnalyticsService.event('purchase_error', {
            'plan': option?.basePlanId,
            'result': 'not_active',
          });
        }
        _purchaseOption = null;
      }
    } on Object catch (error) {
      debugPrint('Falha ao validar assinatura: $error');
      purchasePending = false;
      storeMessage = tr.storeValidationError;
      if (isNewPurchase) {
        AnalyticsService.event('purchase_error', {
          'plan': option?.basePlanId,
          'result': 'validation_failed',
        });
        _purchaseOption = null;
      }
      if (isRequestedRestore) _finishRequestedRestore('error');
    }
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    _authSubscription?.cancel();
    _entitlementSubscription?.cancel();
    _restoreTimeout?.cancel();
    super.dispose();
  }
}
