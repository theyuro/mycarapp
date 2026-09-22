import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:path_provider/path_provider.dart';

import '../models/subscription_entitlement.dart';

class SubscriptionOption {
  const SubscriptionOption({
    required this.product,
    required this.basePlanId,
    required this.billingPeriod,
    required this.price,
    required this.renewalPrice,
    required this.offerTags,
    this.offerId,
  });

  final ProductDetails product;
  final String basePlanId;
  final String billingPeriod;
  final String price;
  final String renewalPrice;
  final String? offerId;
  final List<String> offerTags;

  bool get isAnnual => billingPeriod == 'P1Y';
  bool get isPromotional => offerId != null;
  String get title => isAnnual ? 'Plano anual' : 'Plano mensal';

  String get priceDescription {
    if (isPromotional && price != renewalPrice) {
      return '$price na oferta; depois $renewalPrice${isAnnual ? '/ano' : '/mês'}';
    }
    return '$renewalPrice${isAnnual ? '/ano' : '/mês'}';
  }
}

class AccessService extends ChangeNotifier {
  AccessService._();

  static final AccessService instance = AccessService._();
  static const subscriptionProductId = 'mycarapp_subscription';
  static const trialDuration = Duration(days: 14);

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
  DateTime? _trialStartedAt;
  DateTime? _lastSeenAt;
  bool _subscriptionActive = false;
  bool _betaPremiumActive = DateTime.now().isBefore(DateTime(2026, 8, 31));
  String? _boundUid;
  List<ProductDetails> _storeProducts = const [];
  Set<String> _allowedOfferTags = const {};
  SubscriptionEntitlement entitlement =
      const SubscriptionEntitlement.inactive();
  DateTime? premiumFreeUntil = DateTime(2026, 8, 31);
  bool _initialized = false;
  bool storeAvailable = false;
  bool loadingStore = true;
  bool purchasePending = false;
  List<SubscriptionOption> subscriptionOptions = const [];
  SubscriptionOption? selectedSubscription;
  String? storeMessage;

  bool get subscriptionActive => _subscriptionActive || _betaPremiumActive;
  bool get paidSubscriptionActive => _subscriptionActive;
  bool get betaPremiumActive => _betaPremiumActive;
  bool get signedIn => _auth.currentUser != null;
  ProductDetails? get subscriptionProduct => selectedSubscription?.product;

  Duration get trialRemaining {
    final started = _trialStartedAt;
    if (started == null) return Duration.zero;
    final now = DateTime.now();
    final safeNow = _lastSeenAt != null && now.isBefore(_lastSeenAt!)
        ? _lastSeenAt!
        : now;
    final remaining = trialDuration - safeNow.difference(started);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  int get trialDaysRemaining {
    final remaining = trialRemaining;
    if (remaining == Duration.zero) return 0;
    return (remaining.inHours / 24).ceil();
  }

  bool get trialActive => trialRemaining > Duration.zero;
  bool get hasAccess => subscriptionActive || trialActive;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _loadState();
    final now = DateTime.now();
    _trialStartedAt ??= now;
    if (_lastSeenAt == null || now.isAfter(_lastSeenAt!)) _lastSeenAt = now;
    await _saveState();

    _purchaseSubscription = _store.purchaseStream.listen(
      _handlePurchases,
      onError: (Object error) {
        purchasePending = false;
        storeMessage = 'Não foi possível concluir a comunicação com a loja.';
        notifyListeners();
      },
    );
    _authSubscription = _auth.authStateChanges().listen(
      (user) => unawaited(_bindUser(user)),
    );
    await _bindUser(_auth.currentUser);
    unawaited(_loadRemoteAccess());
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
    await _loadPromotionEligibility();
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
        storeMessage = 'Google Play não está disponível neste aparelho.';
        return;
      }
      final response = await _store.queryProductDetails({
        subscriptionProductId,
      });
      if (response.error != null) {
        storeMessage = response.error!.message;
      } else if (response.productDetails.isEmpty) {
        storeMessage =
            'Produto não encontrado. Confirme o ID no Google Play Console.';
      } else {
        _storeProducts = response.productDetails;
        _refreshSubscriptionOptions();
        storeMessage = subscriptionOptions.isEmpty
            ? 'Nenhum plano disponível para esta conta.'
            : null;
      }
      if (_auth.currentUser != null) await _store.restorePurchases();
    } on Object catch (error) {
      debugPrint('Falha ao conectar à Google Play: $error');
      storeMessage = 'Não foi possível acessar a Google Play.';
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
          offerId: details.offerId,
          offerTags: List.unmodifiable(details.offerTags),
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
    selectedSubscription ??= _firstWhereOrNull(
      options,
      (option) => !option.isAnnual && !option.isPromotional,
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

  Future<void> buySubscription() async {
    final user = _auth.currentUser;
    final option = selectedSubscription;
    if (user == null) {
      storeMessage = 'Entre com sua conta Google para assinar.';
      notifyListeners();
      return;
    }
    if (option == null || purchasePending) return;
    purchasePending = true;
    storeMessage = null;
    notifyListeners();
    try {
      final started = await _store.buyNonConsumable(
        purchaseParam: PurchaseParam(
          productDetails: option.product,
          applicationUserName: user.uid,
        ),
      );
      if (!started) {
        purchasePending = false;
        storeMessage = 'A compra não pôde ser iniciada.';
        notifyListeners();
      }
    } on Object catch (error) {
      debugPrint('Falha ao iniciar assinatura: $error');
      purchasePending = false;
      storeMessage = 'Não foi possível iniciar a compra.';
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    if (_auth.currentUser == null) {
      storeMessage = 'Entre com sua conta Google para restaurar a assinatura.';
      notifyListeners();
      return;
    }
    if (!storeAvailable || purchasePending) return;
    purchasePending = true;
    storeMessage = 'Procurando compras anteriores...';
    notifyListeners();
    try {
      await _store.restorePurchases();
      storeMessage = _subscriptionActive
          ? 'Assinatura restaurada.'
          : 'Compras consultadas. Validando com a Google Play...';
    } on Object catch (error) {
      debugPrint('Falha ao restaurar assinatura: $error');
      storeMessage = 'Não foi possível restaurar as compras.';
    } finally {
      purchasePending = false;
      notifyListeners();
    }
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != subscriptionProductId) continue;
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyAndComplete(purchase);
          break;
        case PurchaseStatus.pending:
          purchasePending = true;
          storeMessage = 'Pagamento pendente na Google Play.';
          break;
        case PurchaseStatus.error:
          purchasePending = false;
          storeMessage =
              purchase.error?.message ?? 'A compra não foi concluída.';
          break;
        case PurchaseStatus.canceled:
          purchasePending = false;
          storeMessage = 'Compra cancelada.';
          break;
      }
    }
    notifyListeners();
  }

  Future<void> _verifyAndComplete(PurchaseDetails purchase) async {
    final user = _auth.currentUser;
    if (user == null) {
      purchasePending = false;
      storeMessage = 'Entre na mesma conta usada para iniciar a assinatura.';
      return;
    }
    final token = purchase.verificationData.serverVerificationData.trim();
    if (token.isEmpty) {
      purchasePending = false;
      storeMessage = 'A Google Play não forneceu os dados para validação.';
      return;
    }

    purchasePending = true;
    storeMessage = 'Validando assinatura com a Google Play...';
    notifyListeners();
    try {
      final result = await _functions
          .httpsCallable('verifyAndroidSubscription')
          .call({'purchaseToken': token});
      final data = Map<String, dynamic>.from(result.data as Map);
      entitlement = SubscriptionEntitlement.fromJson(data);
      _subscriptionActive = entitlement.active;
      purchasePending = false;
      storeMessage = entitlement.active
          ? 'Assinatura MyCarApp ativa.'
          : 'A assinatura não está ativa na Google Play.';
      if (entitlement.active && purchase.pendingCompletePurchase) {
        await _store.completePurchase(purchase);
      }
    } on Object catch (error) {
      debugPrint('Falha ao validar assinatura: $error');
      purchasePending = false;
      storeMessage =
          'Não foi possível validar a assinatura. Tente restaurar novamente.';
    }
  }

  Future<File> _stateFile() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}MyCarApp',
    );
    if (!await directory.exists()) await directory.create(recursive: true);
    return File('${directory.path}${Platform.pathSeparator}access.json');
  }

  Future<void> _loadState() async {
    final file = await _stateFile();
    if (!await file.exists()) return;
    try {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      _trialStartedAt = json['trialStartedAt'] == null
          ? null
          : DateTime.parse(json['trialStartedAt'] as String);
      _lastSeenAt = json['lastSeenAt'] == null
          ? null
          : DateTime.parse(json['lastSeenAt'] as String);
      // Estados Premium antigos eram locais e não são mais considerados.
      _subscriptionActive = false;
    } on Object {
      _trialStartedAt = DateTime.now();
      _lastSeenAt = DateTime.now();
      _subscriptionActive = false;
    }
  }

  Future<void> _saveState() async {
    final file = await _stateFile();
    final temporary = File('${file.path}.tmp');
    final backup = File('${file.path}.bak');
    await temporary.writeAsString(
      jsonEncode({
        'trialStartedAt': _trialStartedAt?.toIso8601String(),
        'lastSeenAt': _lastSeenAt?.toIso8601String(),
      }),
      flush: true,
    );
    if (await backup.exists()) await backup.delete();
    if (await file.exists()) await file.rename(backup.path);
    try {
      await temporary.rename(file.path);
      if (await backup.exists()) await backup.delete();
    } catch (_) {
      if (!await file.exists() && await backup.exists()) {
        await backup.rename(file.path);
      }
      rethrow;
    }
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    _authSubscription?.cancel();
    _entitlementSubscription?.cancel();
    super.dispose();
  }
}
