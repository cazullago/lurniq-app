import 'package:flutter_test/flutter_test.dart';
import 'package:lurniq/models/models.dart';

/// Unit tests for the Lurniq Plus subscription foundation:
/// [PlusCatalog] price formatting and [Entitlement.isPlus] semantics.
void main() {
  group('PlusCatalog.priceLine', () {
    test('PHP preference shows peso price with USD approximation', () {
      expect(PlusCatalog.priceLine(149, 'month', 'PHP'),
          '₱149/month (≈ \$2.57/month)');
    });

    test('USD preference shows dollar price with peso reference', () {
      expect(PlusCatalog.priceLine(149, 'month', 'USD'),
          '\$2.57/month (≈ ₱149/month)');
    });

    test('yearly PHP price line', () {
      expect(PlusCatalog.priceLine(999, 'year', 'PHP'),
          '₱999/year (≈ \$17.22/year)');
    });

    test('yearly USD price line', () {
      expect(PlusCatalog.priceLine(999, 'year', 'USD'),
          '\$17.22/year (≈ ₱999/year)');
    });

    test(
        'other currency preferences fall back to PHP-first display',
        () {
      expect(PlusCatalog.priceLine(149, 'month', 'EUR'),
          '₱149/month (≈ \$2.57/month)');
    });

    test('catalog constants match the advertised tiers', () {
      expect(PlusCatalog.monthlyPhp, 149);
      expect(PlusCatalog.yearlyPhp, 999);
    });
  });

  group('Entitlement.isPlus', () {
    test('active subscription counts as Plus', () {
      final e = Entitlement(
        plan: 'plus',
        source: 'play_billing',
        plusExpiresAt:
            DateTime.now().add(const Duration(days: 30)),
      );
      expect(e.isPlus, isTrue);
    });

    test('expired subscription is not Plus', () {
      final e = Entitlement(
        plan: 'plus',
        source: 'play_billing',
        plusExpiresAt: DateTime.now()
            .subtract(const Duration(days: 1)),
      );
      expect(e.isPlus, isFalse);
    });

    test('demo grant counts as Plus', () {
      final e = Entitlement(plan: 'plus', source: 'demo');
      expect(e.isPlus, isTrue);
    });

    test('default entitlement is not Plus', () {
      expect(Entitlement().isPlus, isFalse);
    });

    test('JSON round trip preserves Plus state', () {
      final e = Entitlement(
        plan: 'plus',
        source: 'play_billing',
        plusExpiresAt: DateTime(2030, 6, 1),
      );
      final restored = Entitlement.fromJson(e.toJson());
      expect(restored.isPlus, isTrue);
      expect(restored.plan, 'plus');
      expect(restored.source, 'play_billing');
    });
  });
}
