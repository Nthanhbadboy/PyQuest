# a02-shared-settings · Shared Settings

**Batch A · concept + screen study only.**

- [Open localized layout](layout.html) · [Full-size art](concept.png) · [Exact generation prompt](prompt.txt)
- States: `system_active, system_fallback, manual_vi, manual_en, save_error, retry`. The page offers VI/EN and 1×/1.3×/2× text fixture controls; its primary CTA is disabled.
- Reference choice: see [`manifest.json`](manifest.json) for exact active paths and SHA-256; scene-specific rationale is included there and in [`../reviewed-inputs.json`](../reviewed-inputs.json).
- Sources: app/lib/app/settings_sheet.dart, app/lib/core/localization/locale_preference.dart, app/lib/core/settings_service.dart, app/lib/l10n/app_vi.arb, app/lib/l10n/app_en.arb, docs/design/shared-l10n/README.md.
- Runtime/production readiness: **false**. No live data, gameplay, persistence, account, network, grant, purchase or inference is implemented.

The PNG is one opaque concept scene, not a layered/sprite pack. It must not be treated as calibrated geometry or proof of a shipped feature.
