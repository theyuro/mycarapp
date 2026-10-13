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
import '../l10n/l10n.dart';

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
  static const trialDuration = Duration(days: 14);

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
  bool get hasAccess => freeModeEnabled || subscriptionActive || trialActive;

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
        storeMessage = tr.storeCommError;
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
      storeMessage = tr.storeSignInToSubscribe;
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
        storeMessage = tr.storePurchaseNotStarted;
        notifyListeners();
      }
    } on Object catch (error) {
      debugPrint('Falha ao iniciar assinatura: $error');
      purchasePending = false;
      storeMessage = tr.storePurchaseStartError;
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    if (_auth.currentUser == null) {
      storeMessage = tr.storeSignInToRestore;
      notifyListeners();
      return;
    }
    if (!storeAvailable || purchasePending) return;
    purchasePending = true;
    storeMessage = tr.storeSearching;
    notifyListeners();
    try {
      await _store.restorePurchases();
      storeMessage = _subscriptionActive
          ? tr.storeRestored
          : tr.storeValidatingRestore;
    } on Object catch (error) {
      debugPrint('Falha ao restaurar assinatura: $error');
      storeMessage = tr.storeRestoreError;
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
          storeMessage = tr.storePending;
          break;
        case PurchaseStatus.error:
          purchasePending = false;
          storeMessage = purchase.error?.message ?? tr.storeNotCompleted;
          break;
        case PurchaseStatus.canceled:
          purchasePending = false;
          storeMessage = tr.storeCanceled;
          break;
      }
    }
    notifyListeners();
  }

  Future<void> _verifyAndComplete(PurchaseDetails purchase) async {
    final user = _auth.currentUser;
    if (user == null) {
      purchasePending = false;
      storeMessage = tr.storeSameAccount;
      return;
    }
    final token = purchase.verificationData.serverVerificationData.trim();
    if (token.isEmpty) {
      purchasePending = false;
      storeMessage = tr.storeNoVerificationData;
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
    } on Object catch (error) {
      debugPrint('Falha ao validar assinatura: $error');
      purchasePending = false;
      storeMessage = tr.storeValidationError;
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
