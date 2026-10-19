# Lurniq Legal Checklist

> The in-app Terms of Service, Privacy Policy, and Tutor Agreement are
> **drafts for review — not legal advice**. Nothing below is a substitute
> for a lawyer. **Do not accept real payments until every gate in this
> file is cleared.**

## 1. Lawyer review (HARD GATE before payments)
- [ ] Engage a lawyer licensed in the Philippines (primary market) to review:
  `lib/screens/legal/legal_screens.dart` (ToS, Privacy Policy, Tutor Agreement).
- [ ] Confirm the 15% commission disclosure, refund windows, and payout
  terms comply with PH consumer-protection rules.
- [ ] Confirm the independent-contractor framing for tutors holds under
  PH labor law (no accidental employer relationship).
- [ ] Re-stamp `LegalVersions` and require re-acceptance after any change
  (`tutorAgreementAccepted` / sign-up versions enforce this in code).

## 2. Business registration & tax (Philippines)
- [ ] Register the operating entity: DTI (sole proprietor) or SEC
  (corporation/partnership), then BIR (Certificate of Registration, official
  receipts/invoices for commission income).
- [ ] Determine VAT vs. non-VAT status; confirm whether the 15% commission
  is vatable and how it is invoiced.
- [ ] Decide tutor tax handling: tutors are independent (they handle their
  own taxes — stated in the Tutor Agreement), but confirm if the platform
  must withhold on payouts under PH rules (expanded withholding tax on
  professional fees) once Stripe Connect or equivalent is live.
- [ ] Keep BIR-compliant records of every commission, payout, and refund
  (the app already records all three in the tutor dashboard data model).

## 3. Data Privacy Act of 2012 (Republic Act No. 10173) / NPC
- [ ] Appoint a Data Protection Officer before collecting server-side data.
- [ ] Register data processing systems with the National Privacy Commission
  if thresholds apply.
- [ ] Publish the Privacy Policy (in-app) and a public URL for Play Store
  listing; keep the data-subject rights flow (access/correction/deletion)
  working — account deletion already wipes on-device data.
- [ ] Data Processing Agreements with every processor: payment provider,
  crash reporting, analytics (when added).
- [ ] Breach notification procedure (NPC + affected users within 72 hours).

## 4. Google Play Data Safety form (maps to current code)
| Data type | Collected? | Notes |
|---|---|---|
| Name, email (optional) | Yes | Account identity |
| Photos / videos | Yes | Lesson photos, post images, profile/course pictures — user-initiated only |
| App activity (posts, bookings) | Yes | Core features |
| Precise location | No | Never collected |
| Contacts / calendar | No | Never accessed |
| Financial info | No | Goes directly to the payment provider when payments launch |
| Advertising ID | No | No ads SDK |

- [ ] Fill the Data Safety form in Play Console to match this table.
- [ ] Update the table + form the moment server-side collection begins.

## 5. Payments (Phase 4 — all user-side)
- [ ] Choose a marketplace payout provider that supports PH tutors
  (Stripe Connect is the reference; confirm PH payout availability, else
  evaluate PayMongo/Xendit + manual payout flow).
- [ ] Implement: payment intents, 15% application fee, destination charges
  to tutor accounts, refund API mapping to the ToS refund windows.
- [ ] Money never touches Lurniq accounts except the commission (boundary
  already in the product spec — no user-to-user wallets).

## 6. Age verification & minor safety
- [ ] Tutors: 18+ verified at application (government ID check via the
  payment provider's KYC or a verification vendor — decided before tutor
  payouts go live).
- [ ] Students: 13+ (or higher local minimum); under-18 needs parental
  consent for paid features — implement the consent capture before
  payments launch.
- [ ] Keep in place: restricted messaging, report/block everywhere,
  adult–minor interaction rules in the ToS, prioritized safety reports.

## 7. Content & IP
- [ ] Repeat-infringer policy for course content (tutors uploading
  copyrighted slides/videos).
- [ ] Trademark check on the "Lurniq" name/logo in PH (and US/EU if
  expanding) before public launch.

## 8. Launch order
1. Lawyer signs off on legal texts → bump `LegalVersions`, ship update.
2. BIR registration complete; DPO appointed.
3. Play Data Safety form submitted; privacy policy URL live.
4. Payment provider connected in test mode → production.
5. Tutor KYC/age verification live.
6. Only then: enable paid courses/bookings and Lurniq Plus billing.
