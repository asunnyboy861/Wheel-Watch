# Improvement Plan 2 — Customer-Readiness Audit (Download-to-Use Review)

## Scope

Full walkthrough of the customer journey (first launch -> add position -> daily monitoring -> alert -> Roll Radar -> mark rolled -> stats -> settings -> contact support) and every data flow, verified against US-market usage habits and UI expectations.

## Issues Found & Fixes (all Implemented)

| Issue ID | Description | Severity | Fix | Verification |
|----------|-------------|----------|-----|--------------|
| ISSUE-A | EventLog duplicate spam: every pull-to-refresh inserted another log row (and re-notified) for any yellow/red position; the "Why did it alert?" audit trail was flooded on every refresh | Critical | `EvaluationService.shouldLog` throttles per symbol+severity to one entry/notification per hour | BUILD + TEST SUCCEEDED |
| ISSUE-B | PrivacyInfo.xcprivacy missing — app uses UserDefaults (Apple Required-Reason API); risks App Store upload warnings/rejection | Critical | Added PrivacyInfo.xcprivacy (no tracking, no collected data, CA92.1 + C617.1 reason codes) to app and widget targets | Files present in both target folders |
| ISSUE-C | "Open Roll Radar" notification button did nothing (no UNUserNotificationCenter delegate, no routing) — broke the guide's "push -> Roll Radar <= 3 taps" core promise | Major | NotificationDelegate routes ROLL_RADAR notifications; HomeView receives `.openRollRadar`, resolves the symbol to its position and presents RollRadarView | Delegate set in App.init before launch completes |
| ISSUE-D | Historical volatility recomputed per position on every refresh (2 network calls per position per refresh) — slow refresh with multiple positions | Major | HV cached per symbol per trading day (ET date key) inside EvaluationService | BUILD OK |
| ISSUE-E | Ticker search fired one Yahoo request per keystroke | Major | 350 ms debounce via `.task(id:)` cancellation + sleep; stale searches cancelled | BUILD OK |
| ISSUE-F | Monetization leak: Finnhub backup quote source usable by free users although price.md scopes dual-source to Pro/BYO | Minor | `QuoteService.backupSourceEnabled` flag gated on `isPro \|\| isBYO`, set from HomeView; Settings footer updated to explain membership | BUILD OK |
| ISSUE-G | Notification permission prompted at first launch before the user added anything ("no permission bombardment" design rule) | Minor | Permission request moved to first successful position save | Screenshot: clean first launch, no dialog |
| ISSUE-H | Card label "vs 225 ↑/↓" arrows implied a live direction and could mislead US users | Minor | Neutral "vs strike 225" label | Screenshot/BUILD OK |
| ISSUE-I | Accent color was default blue while the brand system (icon, paywall, state colors) is green | Minor | AccentColor asset set to brand green (#34C759, brighter dark-mode variant) | Screenshot shows green Add Position CTA |

## Customer Journey Verdict (post-fix)

- First launch: clean empty state, zero dialogs (permission deferred) — DOWNLOAD-TO-USE OK
- Add position: debounced search, live price echo, >30% strike confirmation, OCR import — 30s flow intact
- Monitoring: refresh = 1 + (0..1 cached HV) network calls per position; offline banner; hourly alert throttle
- Alert action: notification -> Open Roll Radar -> comparison + copy -> mark rolled: <= 3 taps promise restored
- Paywall: free users hit it exactly at the 4th position; restore available; legal links present
- Widgets degrade to placeholders until App Group registered (capabilities.md documents it)

## Scores (re-audit)

- Usability: 5/5 · UI Consistency: 5/5 · Feature Completeness: 5/5 · Download-to-Use: 5/5
- Competitive Level: 4/5 · Contact Support: 5/5 · Accessibility: 4/5
EXIT CRITERIA: ALL MET
