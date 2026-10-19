/// Version stamps for the legal documents. Bumped whenever the text
/// changes; users who accepted an older version are asked to re-accept.
///
/// Imported by both the store (stamping acceptances) and the legal screens
/// (displaying documents) — kept separate from the screens to avoid an
/// import cycle with app_store.dart.
class LegalVersions {
  static const tos = '2026-10-19-draft1';
  static const privacyPolicy = '2026-10-19-draft1';
  static const tutorAgreement = '2026-10-19-draft1';
}
