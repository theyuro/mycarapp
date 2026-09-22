import 'package:flutter_test/flutter_test.dart';
import 'package:my_car_app/models/subscription_entitlement.dart';

void main() {
  final now = DateTime.utc(2026, 9, 3, 12);

  test('mantém acesso após cancelamento até a data de expiração', () {
    final entitlement = SubscriptionEntitlement.fromJson({
      'active': true,
      'state': 'SUBSCRIPTION_STATE_CANCELED',
      'expiryTime': '2026-09-10T12:00:00Z',
    }, now: now);

    expect(entitlement.active, isTrue);
  });

  test('remove acesso quando a assinatura está expirada', () {
    final entitlement = SubscriptionEntitlement.fromJson({
      'active': true,
      'state': 'SUBSCRIPTION_STATE_ACTIVE',
      'expiryTime': '2026-09-01T12:00:00Z',
    }, now: now);

    expect(entitlement.active, isFalse);
  });

  test('não concede acesso sem estado ativo do servidor', () {
    final entitlement = SubscriptionEntitlement.fromJson({
      'active': false,
      'state': 'SUBSCRIPTION_STATE_ON_HOLD',
      'expiryTime': '2026-09-10T12:00:00Z',
    }, now: now);

    expect(entitlement.active, isFalse);
  });

  test('aceita o schema padronizado de entitlement', () {
    final entitlement = SubscriptionEntitlement.fromJson({
      'status': 'grace_period',
      'planId': 'premium_monthly',
      'expiresAt': '2026-09-10T12:00:00Z',
    }, now: now);

    expect(entitlement.active, isTrue);
    expect(entitlement.basePlanId, 'premium_monthly');
  });
}
