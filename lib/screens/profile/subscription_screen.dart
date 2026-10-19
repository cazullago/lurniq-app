import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../store/app_store.dart';

/// Lurniq Plus subscription screen.
///
/// Prices come from [PlusCatalog]. The subscribe buttons are placeholders:
/// they show a "coming soon" dialog and perform NO financial transaction.
class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  void _comingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(S.comingSoon),
        content: const Text(S.comingSoonNote),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(S.ok),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final isPlus = store.isPlus;
    final currency = store.currentUser?.currency ?? 'PHP';

    final monthlyPrice = PlusCatalog.priceLine(
        PlusCatalog.monthlyPhp, S.perMonth, currency);
    final yearlyPrice = PlusCatalog.priceLine(
        PlusCatalog.yearlyPhp, S.perYear, currency);
    // Yearly vs 12 × monthly, kept honest if prices ever change.
    final offPct = ((1 -
                PlusCatalog.yearlyPhp /
                    (PlusCatalog.monthlyPhp * 12)) *
            100)
        .toStringAsFixed(0);

    const plusFeatures = [
      S.unlimitedAi,
      S.noKeyNeeded,
      S.earlyAccess,
      S.supporterBadge,
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text(
          S.plusTitle,
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Premium hero: signature gradient, legibility scrim so the
          // white display text keeps strong contrast in both modes.
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.heroGradient(brightness),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(32),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.22),
                    Colors.black.withValues(alpha: 0.04),
                  ],
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.of(context).padding.top + 64,
                20,
                28,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white
                          .withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    S.plusTitle,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    S.plusTagline,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: Colors.white
                          .withValues(alpha: 0.92),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white
                          .withValues(alpha: 0.2),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${S.currentPlan}: ${isPlus ? S.plusTitle : S.freeTier}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _TierCard(
            title: S.freeTier,
            price: null,
            features: [
              S.everythingInFree,
              '${SubscriptionApi.freeDailyAiQuota} '
                  '${S.dailyAiQuotaNote}',
            ],
            current: !isPlus,
          ),
          _TierCard(
            title: S.plusMonthly,
            price: monthlyPrice,
            features: plusFeatures,
            current: false,
            onSubscribe: () => _comingSoon(context),
          ),
          _TierCard(
            title: S.plusYearly,
            price: yearlyPrice,
            features: plusFeatures,
            badge: S.bestValue,
            note: '≈$offPct% off vs monthly',
            current: false,
            featured: true,
            onSubscribe: () => _comingSoon(context),
          ),
          Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              '${S.comingSoonNote}\n\n${S.approxRateNote}',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(
                      color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.title,
    required this.price,
    required this.features,
    this.badge,
    this.note,
    this.current = false,
    this.featured = false,
    this.onSubscribe,
  });

  final String title;
  final String? price;
  final List<String> features;
  final String? badge;
  final String? note;
  final bool current;
  final bool featured;
  final VoidCallback? onSubscribe;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final priceValue = price;
    final card = Card(
      elevation: featured ? 4 : 2,
      margin: featured
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(
              horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                            fontWeight: FontWeight.w800),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.tertiaryContainer,
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: scheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                if (current)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                    child: Text(
                      S.currentPlan,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
            if (priceValue != null) ...[
              const SizedBox(height: 4),
              Text(
                priceValue,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
              ),
            ],
            if (note != null) ...[
              const SizedBox(height: 2),
              Text(
                note!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
            const SizedBox(height: 10),
            ...features.map(
              (f) => Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_rounded,
                        size: 18, color: scheme.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f)),
                  ],
                ),
              ),
            ),
            if (onSubscribe != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onSubscribe,
                  child: const Text(S.subscribe),
                ),
              ),
            ],
          ],
        ),
      ),
    );
    if (!featured) return card;
    // Featured tier gets the signature gradient border.
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient(brightness),
        borderRadius: BorderRadius.circular(22),
      ),
      child: card,
    );
  }
}
