import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/promotion_eligibility.dart';
import '../models/support_ticket.dart';

class AccountCloudService {
  AccountCloudService({FirebaseAuth? auth, FirebaseFunctions? functions})
    : _auth = auth ?? FirebaseAuth.instance,
      _functions =
          functions ??
          FirebaseFunctions.instanceFor(region: 'southamerica-east1');

  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<String> ensureProfile() async {
    _requireUser();
    final result = await _functions.httpsCallable('ensureUserProfile').call();
    final data = Map<String, dynamic>.from(result.data as Map);
    return data['referralCode'] as String;
  }

  Future<void> applyReferralCode(String code) async {
    _requireUser();
    await _functions.httpsCallable('applyReferralCode').call({
      'code': code.trim().toUpperCase(),
    });
  }

  Future<PromotionEligibility> getPromotionEligibility() async {
    _requireUser();
    final result = await _functions
        .httpsCallable('getPromotionEligibility')
        .call();
    return PromotionEligibility.fromJson(
      Map<String, dynamic>.from(result.data as Map),
    );
  }

  Future<Map<String, dynamic>> verifyAndroidSubscription({
    required String purchaseToken,
  }) async {
    _requireUser();
    final result = await _functions
        .httpsCallable('verifyAndroidSubscription')
        .call({'purchaseToken': purchaseToken});
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<String> createSupportTicket({
    required String type,
    required String subject,
    required String message,
  }) async {
    _requireUser();
    final result = await _functions.httpsCallable('createSupportTicket').call({
      'type': type,
      'subject': subject,
      'message': message,
      'appVersion': '1.1.2+4',
    });
    return Map<String, dynamic>.from(result.data as Map)['ticketNumber']
        as String;
  }

  Future<({List<SupportTicket> tickets, bool isAdmin})>
  listSupportTickets() async {
    _requireUser();
    final result = await _functions.httpsCallable('listSupportTickets').call();
    final data = Map<String, dynamic>.from(result.data as Map);
    final tickets = (data['tickets'] as List<dynamic>? ?? [])
        .map(
          (item) =>
              SupportTicket.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
    return (tickets: tickets, isAdmin: data['isAdmin'] as bool? ?? false);
  }

  Future<void> updateSupportTicket({
    required String id,
    required String status,
    required String response,
  }) async {
    _requireUser();
    await _functions.httpsCallable('updateSupportTicket').call({
      'id': id,
      'status': status,
      'adminResponse': response,
    });
  }

  Future<void> updatePremiumFreeUntil(DateTime until) async {
    _requireUser();
    await _functions.httpsCallable('updatePremiumFreeUntil').call({
      'until': until.toUtc().toIso8601String(),
    });
  }

  void _requireUser() {
    if (_auth.currentUser == null) {
      throw StateError('Entre na sua conta para usar este recurso.');
    }
  }
}
