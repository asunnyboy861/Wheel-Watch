# Wheel Watch - iOS Development Guide

> Source: TR-20260913 期权 Wheel 策略持仓警报操作指南 (translated to American English)
> Generated: 2026-09-15

## Executive Summary

**Wheel Watch** is a native iOS traffic-light alert app for retail options sellers running the Wheel Strategy (Cash-Secured Puts → assignment → Covered Calls → repeat). It monitors positions locally using a Black-Scholes-Merton Greeks engine, fires notifications when action is needed (delta drift, ITM breach, profit target, DTE urgency), and hands the user a complete answer via **Roll Radar** — same-month/next-month strike comparisons with net credit estimates and one-tap copyable order parameters.

**Tagline**: "Never miss a roll. Your wheel, on watch."

**Target Audience**: US retail options income traders (r/thetagang, r/Optionswheel — est. 500K–1M active traders, $10K–$500K portfolios).

**Key Differentiators** (the 4-way intersection no competitor covers):
1. **Real push**: Local notifications (free) + server-side per-minute evaluation + APNs (Pro Live tier) — kills the "email alert delay" pain of ThetaPal
2. **Real decisions**: Alert cards ship with Roll Radar — candidate strikes + net credit, copy order params to broker in ≤3 taps
3. **Real cheap**: Free 3-position tier + $34.99 one-time Pro buyout vs. competitors' $240–708/yr subscriptions
4. **Privacy-first**: Positions stored locally (SwiftData). "Data Not Collected" as a marketing asset.

**Compliance Red Lines**: Read-only monitoring + math + notifications only. NO broker order APIs, NO trade execution, NO investment advice. Every alert card footer: "Alerts are informational only. Not investment advice." This avoids App Store finance-category risk (4.3/3.2.2) and state investment-advisor licensing.

**Positioning**: "Your wheel positions' traffic light: it only calls you when action is needed — and when it does, it already knows which strike to roll to."

## App Identity

| Item | Value |
|---|---|
| App Name | Wheel Watch |
| Subtitle | Delta & Roll Alerts |
| Bundle ID | com.zzoutuo.wheelwatch |
| Min iOS | 17.0 |
| Category | Finance |
| Marketing tagline | "Never miss a roll. Your wheel, on watch." |

## Competitive Analysis

| App | Price | Greeks Alerts | Native iOS Push | Roll Comparison | Weakness |
|-----|-------|---------------|-----------------|-----------------|----------|
| ThetaPal | $9.99/mo | Partial (ITM/profit only) | ❌ Web + email | ✅ AI roll | Email alerts delayed; no native push — misses intraday moves |
| Option Samurai | $39–59/mo | ❌ (screening only) | ❌ | ❌ | Expensive; pre-trade only, ignores held positions |
| OptionStrat | ~$20/mo | ❌ | ❌ | ❌ | Pre-trade visualization only |
| QuantWheel | $19–37/mo | Partial | ❌ | Partial | Expensive and heavy, for systematic traders |
| Wheel Strategy Tracker (id6759725194) | Free + IAP | ❌ no live quotes | ❌ | ✅ journal-only rolls | Pure journal, zero alerting |
| Wheel Flow (id6736965624) | Free + sub | ❌ ticker price only | Weak | ❌ | No Greeks, no roll decisions |
| OptionsPilot (id6755564042) | Free + IAP | Partial (assignment/expiry) | Partial | Partial | AI strike finder, no delta-threshold push |
| WheelAI (id6772432618) | $6.99/mo or $49.99/yr | ❌ | Push for expiry/assignment only | ❌ | No Greeks jargon by design; no delta alerts |

**Conclusion**: Greeks-threshold push + one-tap roll comparison + low price + native iOS = verified market gap. That gap is this product.

**Pain Point Evidence (r/thetagang, r/Optionswheel)**:
> "Is there a platform that offers notifications for delta changes? I'm doing the wheel... I would love to be notified when my positions hit a certain delta value." — r/Optionswheel post 1jqd5d3

**Pain list (ranked)**: P1 delta drift requires manual watching · P2 roll timing/comparison costs 20 min per event · P3 ITM/assignment surprise · P4 ex-dividend early exercise · P5 earnings crossing expiry · P6 forgotten adjusted cost basis · P7 expensive web-only pro tools ($240–708/yr).

## Apple Design Guidelines Compliance

- **iOS 26 Liquid Glass materials + SF Symbols 6 + Dynamic Type**: all surfaces adapt; dark mode first (traders watch screens at night) but both modes must be pixel-perfect.
- **Color semantics (exactly 3 state colors, app-wide)**: 🟢 Green `#34C759` (system green) = collecting/ safe · 🟡 Orange `#FF9F0A` = check it · 🔴 Red `#FF3B30` = act now. No fourth state color anywhere.
- **Information density**: Home cards show only 5 decision numbers (price vs strike, |delta|, theta/day income, DTE, unrealized %). Everything else lives in Detail.
- **Typography**: key numbers 34pt rounded design; one-hand glanceable.
- **Haptics**: `UIImpactFeedbackGenerator(.heavy)` when a red card appears — event feel.
- **Empty state**: one sentence "Add your first CSP — 30 seconds." + big button. No marketing art.
- **Icons**: SF Symbols only (e.g. `clock.badge.exclamationmark`). No third-party icon libraries.
- **Notifications**: iOS notification action buttons ("Open Roll Radar" deep link).
- **App icon**: black background + neon-green wheel radar — shelf differentiation in a blue/white finance category.

## Technical Architecture

- **Language**: Swift 5.9+ / Swift 6 concurrency
- **UI**: SwiftUI, iOS 17+ (min deployment 17.0)
- **Persistence**: SwiftData (`Position`, `AlertRuleSet`, `EventLog` entities) — local-only by design
- **Quant engine**: pure-Swift BSM + 5 Greeks + IV bisection (ported from ItoCanvasCore, MIT)
- **Quotes**: Yahoo Finance v8 chart endpoint (primary) → Finnhub (fallback) → explicit OFFLINE state. Never silently serve stale prices as fresh.
- **Local scheduling**: BGAppRefreshTask (~15 min) + trading-hours gating (America/New_York)
- **Notifications**: UNUserNotificationCenter (free tier); APNs via Cloudflare Worker (Pro Live tier — backend configured separately)
- **IAP**: StoreKit 2 — non-consumable Pro buyout + 2 auto-renewable subscriptions
- **Widgets**: WidgetKit — lock-screen accessory countdown ring + medium "top 3 positions + today's theta"
- **OCR import**: VisionKit (on-device, not an AI service)

## ⚠️ Feature Inventory (MANDATORY — Every Feature Must Be Listed)

### Primary Features

| # | Feature | User Operation Flow | Data Input | Processing | Data Output | Persistence | Acceptance Criteria |
|---|---------|--------------------|------------|------------|-------------|-------------|---------------------|
| 1 | Add Position (sheet) | 1. Tap + on Home → 2. Search ticker (e.g. AAPL) → 3. Pick style preset Safe/Balanced/Spicy → 4. Enter type (CSP/CC), strike, premium, expiry, quantity OR tap screenshot-OCR import → 5. Confirm (price sanity check) | Ticker, type, strike, premium, expiry, qty, or broker screenshot | Ticker search via Yahoo symbol lookup; OCR prefill via VisionKit; validation: if entered strike's market mid deviates >30% from implied → confirmation dialog; compute current Greeks preview | Confirmable prefilled form with live quote echo; position saved and appears on Home card stream | SwiftData `Position` | Adding one position takes ≤30 s; entry with strike deviating >30% from market triggers confirm dialog |
| 2 | Home traffic-light stream | 1. Open app → 2. Cards auto-sorted by severity (red top) → 3. Pull to refresh → 4. Swipe left to delete / mark Rolled | Position list + live quotes + rule evaluation | RuleEngine evaluate per position → Severity green/yellow/red; dedupe: same ticker ≥5 min; batch-merge max 3 into digest | Card stream: each card shows 5 numbers (price vs strike, |delta|, theta/day, DTE, unrealized %) + quote timestamp (stale data flagged yellow) | SwiftData `Position`, `EventLog` | Green = nothing to do; yellow/red show reason line; red triggers heavy haptic; timestamp always visible |
| 3 | Greeks engine (local BSM) | Automatic on every refresh | S, K, T, r, σ inputs | BSM closed-form: delta/theta/day/gamma/vega; IV solved from option mid via bisection [1%,300%] ×20 iters; if bid/ask both 0 → fall back to 30-day HV and set `ivEstimated` | GreeksResult consumed by RuleEngine + displayed in Detail | In-memory per refresh | Unit tests: delta error <0.02 vs textbook BS values (e.g. S=100,K=100,T=1,σ=0.2,r=0.05 call delta≈0.636); IV solve converges |
| 4 | Rule engine + 3 preset templates | Settings → pick Safe (0.20Δ/0.75 profit/7 DTE), Balanced (0.30/0.50/7), Spicy (0.40/0.50/5); rules editable | AlertMetric enum: deltaThreshold, profitTarget, dteUrgent, itmBreach, exDividendRisk, earningsCross | Pure-function evaluate(snapshot, rules) → (Severity, [messages]); same input ⇒ same output (testable, replayable, Worker-replicable) | Severity + per-rule trigger messages | SwiftData `AlertRuleSet` | All 6 metric types evaluate correctly; after-close no false positives (Closed state); presets one-tap applied |
| 5 | Local notifications (free tier) | First launch → permission prompt; user enables Background Refresh | BGAppRefreshTask ~15 min + market-hours gate (9:30–16:00 ET) | Evaluate all positions; quiet hours 21:00–06:30 ET suppressed; DTE≤7/ex-div/earnings are time-point local notifications | UNUserNotification with red/yellow/green grading + "Open Roll Radar" action | UNUserNotificationCenter | 5 default alert types fire correctly; ≤60 s from refresh to visible is not guaranteed but notification arrives on next BG window; free tier discloses "local refresh subject to iOS scheduling" |
| 6 | Roll Radar (modal) | From red/yellow card or Detail button → compare same-month vs next-month candidate strikes → net credit estimate → Copy order params | Option chain snapshot (Yahoo options endpoint) | Filter same-expiry and next-expiry strikes near target delta; compute net credit (new premium − close cost); format order text: `SELL 1 AAPL PUT 225 30D ~$1.20` | Comparison table + net credit + one-tap copy; disclaimer footer | None (recomputed live) | Push → Roll Radar → copied order params ≤3 taps; copy toast confirms |
| 7 | Position Detail | Tap any card → full Greeks, EventLog ("why did this alert fire"), P&L curve | Position + EventLog history + quote history | Render Greeks w/ ivEstimated yellow dot; audit trail list | Detail screen w/ persistent Roll Radar button | SwiftData `EventLog` | EventLog shows time/snapshot price/delta/rule for every trigger; "estimated" IV visibly flagged |
| 8 | Stats, badges & share card | Stats tab → cumulative premium, win rate, annualized yield; milestone badges $1K/$5K/$10K → generate share card → share to Reddit/X | Position history + premium ledger | Aggregate stats (Decimal math); badge thresholds; render share image with app watermark | Stats screen + shareable achievement card | SwiftData aggregates + UserDefaults badges | Numbers match ledger; share card includes disclaimer + watermark |
| 9 | Mark as Rolled / lifecycle | Swipe left on card → Mark Rolled (roll executed) or Close | New premium/strike/expiry | Update cost basis (adjusted for rolls); write EventLog; reset alert state | Card returns to green; cost basis updated | SwiftData `Position` | Post-roll CC sells below adjusted basis are flagged |
| 10 | Daily close report | After 16:00 ET market close (or next BG window) | Day's theta + premium events | Sum theta/day income across positions → digest | Local notification: "Today 3 positions collected $47.50 for you" | — | One digest/day; friendly copy; no push during quiet hours |
| 11 | Dual-source quotes + offline visibility | Automatic; user sees source & timestamp | Yahoo v8 chart → Finnhub fallback | Health check, exponential-backoff retry; all-down → OFFLINE state + user notification; cached quotes carry timestamps | Card timestamp; offline banner; "Data offline" push | Quote cache | Unplug-network test shows offline banner (never stale-as-fresh, never crash) |
| 12 | Pro buyout IAP ($34.99; launch early-bird $24.99) | Paywall after 4th position added or from Settings | StoreKit 2 purchase | Non-consumable unlock: unlimited positions, Roll Radar, widgets+Dynamic Island, iCloud sync, dual quote source, badges | Pro features unlocked; purchase restored via restore button | StoreKit 2 + UserDefaults entitlement | Sandbox purchase/restore works; 4th-position wall triggers paywall |
| 13 | Live cloud push subscription (Wheel Watch Live, $4.99/mo or $29.99/yr, 7-day trial) | Paywall → subscribe → device token registered | APNs device token + minimal rule fields | Cloudflare Worker cron (every minute, market hours) replicates RuleEngine → APNs push ≤60 s; subscription validated against App Store Server API every 24 h | True server push; email backup alerts | Backend D1 (minimal encrypted fields) | Trial = full feature; push latency ≤60 s (backend); monthly default display with annual pre-selected per pricing psychology |
| 14 | BYO data source subscription ($1.99/mo or $14.99/yr) | Settings → Enter your own Finnhub/Polygon API key | User API key (keychain) | App polls at 1-min level using user's key; no server dependency | Faster refresh for BYO subscribers | Keychain + UserDefaults flag | Key stored in Keychain; invalid key surfaces visible error |
| 15 | Lock-screen widget (countdown ring) | Add widget → shows nearest-expiry position ring | WidgetKit timeline from app group | DTE-based green/orange/red ring | Lock-screen accessory widget | App Group shared store | Ring color matches app semantics; deep-links on tap |
| 16 | Medium widget (top 3 + today's theta) | Add widget | WidgetKit timeline | Top 3 pending positions + today's theta income | Medium widget | App Group shared store | Tap deep-links to corresponding card |
| 17 | Milestone badges | Auto on premium thresholds | Cumulative premium | $1K/$5K/$10K detection | Badge + share card generator | UserDefaults | Badge awarded exactly once per threshold |

### Sub-Features & Detail Interactions

| # | Parent | Sub-Feature | Behavior | Interaction |
|---|--------|-------------|----------|-------------|
| 1.1 | Add Position | Screenshot OCR import | VisionKit on-device OCR prefills type/strike/premium/expiry; user confirms | Tap button → pick screenshot → review prefills |
| 1.2 | Add Position | Live quote echo | After entry, current option quote shown; >30% mid deviation → confirm dialog | Automatic validation |
| 2.1 | Home | Dedupe/digest | Same ticker suppressed for 5 min; max 3 merged into one digest push | Automatic |
| 2.2 | Home | Stale data flag | Quote older than threshold shows yellow timestamp dot | Automatic |
| 4.1 | Rules | Quiet hours | 21:00–06:30 ET no notifications | Automatic |
| 4.2 | Rules | Trading calendar | All DTE math in America/New_York trading days, not calendar days | Automatic |
| 6.1 | Roll Radar | Deep link to broker | Copy params then suggestion to open broker app | Copy button → toast |
| 8.1 | Stats | Share card watermark | Achievement image includes app name + disclaimer | Share sheet |
| 14.1 | BYO | Key validation | Test call on save; visible error on failure | Save button |

### Cross-Feature Dependencies

| Dependency | Source | Target | Data Passed | Trigger |
|------------|--------|--------|-------------|---------|
| Add Position → Home stream | Feature 1 | Feature 2 | New Position entity | Save |
| Quotes → RuleEngine | Feature 11 | Features 3/4 | StockQuote | Each refresh |
| Greeks → RuleEngine | Feature 3 | Feature 4 | delta/theta/iv | Each refresh |
| RuleEngine → Notifications | Feature 4 | Feature 5 | Severity + messages | Trigger |
| RuleEngine → Roll Radar | Feature 4 | Feature 6 | Position + target delta | Red/yellow card tap |
| Roll copied → Mark Rolled | Feature 6 | Feature 9 | New strike/premium/expiry | User action after execution |
| Events → EventLog → Detail | Features 4/9 | Feature 7 | EventLog entries | Every trigger |
| Premium ledger → Stats/badges | Features 1/9 | Feature 8/17 | Premium amounts | Every close/expire/roll |
| Entitlements → feature gating | Features 12/13/14 | Features 1/5/6/15/16 | Pro/Live/BYO flags | Purchase/restore |
| Position data → widgets | Features 2/10 | Features 15/16 | App Group snapshot | Timeline reload |

**VERIFICATION CHECK**: 17 primary features + 9 sub-features extracted — matches every capability described in the Chinese guide (screens 1–5, widgets A/B, 6 alert metrics, 3 presets, 4 pricing tiers, dedupe, quiet hours, offline visibility, OCR, badges, share card). ✅

## ⚠️ Data Flow Diagram (MANDATORY — Core Feature Lifecycles)

```
Feature: Alert evaluation loop (features 2,3,4,5)
┌───────────────────────────────────────────────────────────┐
│  Inputs                                                   │
│  └── SwiftData Positions + Yahoo/Finnhub quote            │
│       │                                                   │
│  QuoteService (dual-source fallback, cached+timestamped)  │
│  └── fail → backup source → fail → OFFLINE state + push   │
│       │                                                   │
│  GreeksEngine (pure functions)                            │
│  └── IV from option mid (bisection) or 30d HV fallback    │
│       │  (ivEstimated=true → UI yellow dot)               │
│  RuleEngine.evaluate(snapshot, rules) → (Severity, msgs)  │
│       │                                                   │
│  Persistence                                              │
│  └── EventLog(time, price, delta, rule) appended          │
│       │                                                   │
│  Display / Dispatch                                       │
│  └── Home card stream (sorted red-first)                  │
│  └── UNUserNotification (free) / APNs (Live, backend)     │
│  └── Dedupe 5-min per ticker; merge ≤3; quiet hours ET    │
└───────────────────────────────────────────────────────────┘

Feature: Add Position
User input (ticker/type/strike/premium/expiry/qty or OCR)
→ AddPositionViewModel: symbol lookup + validate (>30% mid deviation → confirm)
→ SwiftData Position insert → EventLog "created"
→ Home stream re-evaluates immediately

Feature: Mark Rolled
Swipe → new strike/premium/expiry
→ Position updated + adjusted cost basis recomputed
→ EventLog "rolled" → Stats ledger updated → card re-evaluated

Feature: IAP unlock
Paywall → StoreKit 2 purchase/restore
→ Entitlement stored (Transaction.currentEntitlements verified on launch)
→ Unlimited positions / Roll Radar / widgets / iCloud / dual-source flags on
```

## Module Structure

```
Wheel Watch/
├── Wheel_WatchApp.swift            // entry, SwiftData container, BG task registration
├── Models/
│   ├── Position.swift              // SwiftData entity (type/strike/premium/expiry/qty/basis)
│   ├── AlertRule.swift             // Codable rule + metric enum + presets
│   ├── EventLog.swift              // audit entity
│   └── Entitlement.swift           // StoreKit state mapping
├── Engine/
│   ├── GreeksEngine.swift          // pure BSM + IV bisection (unit-tested)
│   └── RuleEngine.swift            // pure evaluation
├── Services/
│   ├── QuoteService.swift          // Yahoo→Finnhub→offline chain
│   ├── OptionChainService.swift    // chain snapshot for Roll Radar
│   ├── NotificationService.swift   // schedule/grade/dedupe/quiet hours
│   ├── BackgroundRefreshService.swift
│   └── StatsService.swift          // Decimal aggregates + badges
├── ViewModels/
│   ├── HomeViewModel.swift
│   ├── AddPositionViewModel.swift
│   ├── PositionDetailViewModel.swift
│   ├── RollRadarViewModel.swift
│   └── SettingsViewModel.swift
├── Views/
│   ├── HomeView.swift              // traffic-light stream
│   ├── AddPositionView.swift       // sheet + OCR
│   ├── PositionDetailView.swift
│   ├── RollRadarView.swift
│   ├── StatsView.swift
│   ├── SettingsView.swift          // presets, BYO key, IAP links, legal
│   └── PaywallView.swift           // StoreKit 2 + EULA/Privacy links
├── WidgetExtension/                // lock-screen ring + medium widget
├── Tests/                          // GreeksEngine standard-value tests, RuleEngine tests
└── backend/                        // (Pro Live) Cloudflare Worker evaluator + APNs — deploy separately
```

## Implementation Flow

1. SwiftData models: `Position`, `AlertRuleSet`, `EventLog`; app entry + container
2. GreeksEngine port + standard-value unit tests (delta error <0.02, IV convergence)
3. QuoteService dual-source chain + offline state; quote cache w/ timestamps
4. Add Position flow (ticker search, presets, OCR import, >30% validation)
5. RuleEngine (6 metrics, 3 presets) + Home traffic-light stream
6. NotificationService: local push, dedupe, merge, quiet hours, close report
7. Roll Radar: chain snapshot, same/next-month compare, net credit, copy params
8. Detail + EventLog audit; Mark-Rolled cost-basis update
9. Stats, badges, share card
10. WidgetKit extension (ring + medium) via App Group
11. StoreKit 2: buyout + Live sub + BYO sub; paywall w/ EULA/Privacy links
12. Settings: presets, rules editor, BYO key (Keychain), notification prefs
13. Pro Live backend (Cloudflare Worker + D1 + APNs) — separate deployment, marked as manual config

## UI/UX Design Specifications

- **Colors**: semantic 3-state system (green/orange/red as above); neutral surfaces adapt light/dark; dark mode primary
- **Typography**: SF Pro rounded for key numbers (34pt), regular SF for body; Dynamic Type everywhere
- **Layout**: single Home stream; any action ≤2 levels deep, ≤3 taps; 5-number card density
- **Animations**: severity transitions; heavy haptic on red
- **Empty state**: "Add your first CSP — 30 seconds."
- **Iconography**: SF Symbols only
- **Compliance footer**: every alert card ends with "Informational only — not investment advice."

## Code Generation Rules

1. Engines are pure functions — no network/IO in GreeksEngine/RuleEngine; explicit parameters only (testable, replayable, Worker-replicable)
2. Test-first math: BS textbook standard values asserted in unit tests
3. Time: always `TimeZone(identifier: "America/New_York")`; DTE via trading calendar — never bare calendar days
4. Money: `Double` for display, `Decimal` for persistence/statistics — never Float
5. Errors visible: network failures map to UI states (yellow dot / offline banner); never `try?`-swallow into stale-as-fresh
6. Privacy: positions local-only (SwiftData); Live tier uploads minimal encrypted fields; Privacy manifest = Data Not Collected
7. Compliance copy: disclaimer on every alert card; no "guaranteed/profit" wording in store description
8. Version read dynamically via `Bundle.main.infoDictionary` — never hardcode
9. Apple-native first: SwiftUI/SwiftData/WidgetKit/StoreKit 2

## ⚠️ App Store Compliance — Subscriptions

### Guideline 3.1.2(c) — Subscription Information
Paywall MUST include: functional Privacy Policy link, functional Terms of Use (EULA) link, subscription title/length/price, auto-renewal disclosure text.

### Pricing structure (4 tiers — from guide §8.2)
| Tier | Price | Includes |
|---|---|---|
| Free | $0 forever | ≤3 positions, local notifications, single quote source, traffic-light home |
| Pro buyout | $34.99 one-time (early-bird $24.99 first 30 days) | Unlimited positions, Roll Radar, widgets + Dynamic Island, iCloud sync, dual quote source, badges |
| Live subscription | $4.99/mo or $29.99/yr (7-day free trial, annual pre-selected) | Server per-minute evaluation + APNs ≤60 s + email backup |
| BYO data | $1.99/mo or $14.99/yr | User's own Finnhub/Polygon key → 1-min refresh, no server dependency |

Paywall shows competitor price anchor table (Option Samurai $59/mo · ThetaPal $9.99/mo → Wheel Watch $34.99 once). ROI copy: "One correct roll recovers $300+ premium — the app pays for itself 12×." Live tier cannot be buyout (ongoing Worker/APNs costs) — this is disclosed.

## Build & Deployment Checklist

- [ ] GreeksEngine unit tests pass (standard BS values, delta error <0.02)
- [ ] Dual-source fallback: airplane-mode test shows offline banner, no crash, no stale-as-fresh
- [ ] 3 presets apply in one tap
- [ ] Push → Roll Radar → copied order params ≤3 taps
- [ ] Disclaimer on every alert card + store description
- [ ] All 4 pricing tiers validated in StoreKit 2 sandbox
- [ ] Dark/light + Dynamic Type pass
- [ ] Widgets render correct ring colors + deep link
- [ ] Privacy manifest: Data Not Collected (positions local-only)
- [ ] Pro Live backend (Worker + APNs) deployed separately — recorded in capabilities.md as manual config
