# Pricing Configuration — Wheel Watch

## Monetization Model: Freemium with IAP (One-Time Buyout + Auto-Renewable Subscriptions)

Free tier for light users, a one-time Pro buyout attacking subscription fatigue, and two optional auto-renewable subscription services (cloud push and BYO data) whose ongoing server costs require recurring billing.

## Subscription Group
- **Group Name 1**: Wheel Watch Live — products: live.monthly, live.yearly
- **Group Name 2**: Wheel Watch Data — products: byo.monthly, byo.yearly
- **Note**: Pro buyout is a non-consumable and is NOT in any subscription group (see One-Time Purchases). Live and Data are separate services, so they live in separate groups (a user may hold both).

## Subscription Tiers (Auto-Renewable)

### 1. Live Monthly (Wheel Watch Live)
- **Reference Name**: Wheel Watch Live Monthly
- **Product ID**: `com.zzoutuo.wheelwatch.live.monthly`
- **Type**: Auto-renewable subscription
- **Price**: $4.99 USD per month
- **Display Name**: `Wheel Watch Live Monthly` (24 chars, ≤35 ✅)
- **Description**: `Server-grade per-minute alerts with APNs push` (45 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: Wheel Watch Live
- **Restore Purchases**: ✅ Required

### 2. Live Annual (Wheel Watch Live)
- **Reference Name**: Wheel Watch Live Annual
- **Product ID**: `com.zzoutuo.wheelwatch.live.yearly`
- **Type**: Auto-renewable subscription
- **Price**: $29.99 USD per year (50% savings vs monthly)
- **Display Name**: `Wheel Watch Live Annual` (23 chars, ≤35 ✅)
- **Description**: `Per-minute cloud alerts, 50% off vs monthly` (43 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: Wheel Watch Live (same group as monthly)
- **Restore Purchases**: ✅ Required
- **Paywall display**: annual pre-selected, monthly equivalent price shown for comparison

### 3. BYO Data Monthly (Wheel Watch Data)
- **Reference Name**: Wheel Watch BYO Data Monthly
- **Product ID**: `com.zzoutuo.wheelwatch.byo.monthly`
- **Type**: Auto-renewable subscription
- **Price**: $1.99 USD per month
- **Display Name**: `Wheel Watch BYO Data Monthly` (28 chars, ≤35 ✅)
- **Description**: `1-min refresh using your own Finnhub API key` (44 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: Wheel Watch Data
- **Restore Purchases**: ✅ Required

### 4. BYO Data Annual (Wheel Watch Data)
- **Reference Name**: Wheel Watch BYO Data Annual
- **Product ID**: `com.zzoutuo.wheelwatch.byo.yearly`
- **Type**: Auto-renewable subscription
- **Price**: $14.99 USD per year (37% savings vs monthly)
- **Display Name**: `Wheel Watch BYO Data Annual` (27 chars, ≤35 ✅)
- **Description**: `1-min refresh with your own key, 37% off` (40 chars, ≤55 ✅)
- **Localization**: English (US)
- **Subscription Group**: Wheel Watch Data (same group as monthly)
- **Restore Purchases**: ✅ Required

### Differentiation Notes
- Live vs BYO: Live includes the Wheel Watch cloud evaluator + APNs push + email backup (we run the servers). BYO does NOT include any server-side service — the user's own Finnhub/Polygon key powers faster on-device refresh only.
- Annual tiers are the same service as their monthly tier at a discount — standard same-group tiering.

## One-Time Purchases (Non-Consumable)

### 1. Pro One-Time
- **Reference Name**: Wheel Watch Pro
- **Product ID**: `com.zzoutuo.wheelwatch.pro.onetime`
- **Type**: Non-consumable (one-time purchase, permanently unlocked)
- **Price**: $34.99 USD (one-time; launch price $24.99 for the first 30 days via App Store Connect price schedule)
- **Display Name**: `Wheel Watch Pro` (15 chars, ≤35 ✅)
- **Description**: `One-time Pro unlock: all features, forever` (42 chars, ≤55 ✅)
- **Localization**: English (US)
- **Restore Purchases**: ✅ Required
- **Note**: Pro does NOT include Live cloud push (ongoing Worker/APNs cost — subscription only) and does NOT include BYO fast-refresh subscription. Paywall must state this boundary.

## Free Tier (Default)

- **Price**: Free
- **Features**:
  - Up to 3 active positions
  - Traffic-light Home card stream
  - Local notifications via iOS Background Refresh (subject to iOS scheduling)
  - Single quote source (Yahoo Finance)
  - Daily close report
- **Conversion hooks**:
  - "Add your 4th position to unlock unlimited with Pro."
  - "One correct roll recovers $300+ in premium — Pro pays for itself many times over."
  - "Roll Radar hands you the answer: which strike, what credit. Copy, paste, done."
  - "Your data never leaves your iPhone."

## Pro Features Unlocked (All Paid Tiers)

⚠️ Cross-referenced with capabilities.md (PHASE 2): widget extension target created ✅, iCloud entitlements added ✅, dual-source quote service ✅.

| Feature | Free | Pro ($34.99 once) |
|---------|:----:|:-----------------:|
| Active positions | 3 | Unlimited |
| Traffic-light Home stream | ✅ | ✅ |
| Local notifications | ✅ | ✅ |
| Roll Radar (strike compare + net credit + copy params) | ❌ | ✅ |
| Lock-screen + medium widgets | ❌ | ✅ |
| iCloud sync across devices | ❌ | ✅ |
| Dual quote sources (Yahoo + Finnhub fallback) | Single source | ✅ |
| Milestone badges + share card | ❌ | ✅ |
| Live cloud push (per-minute APNs) | ❌ | ❌ Not included — separate Wheel Watch Live subscription |
| BYO 1-min refresh | ❌ | ❌ Not included — separate Wheel Watch Data subscription |

## Free Trial
- **Duration**: 7 days
- **Type**: Free trial (auto-converts to paid subscription)
- **Available for**: Wheel Watch Live (monthly and annual). BYO Data has no trial (trivial price point). Trial = full Live functionality.

## Policy Pages Required
- Support Page: ✅ (must include subscription management + cancellation instructions + purchase restore)
- Privacy Policy: ✅
- Terms of Use (EULA): ✅ (REQUIRED — subscription apps must have Terms)
- **Total policy pages**: 3

## Apple IAP Compliance Checklist
- [x] Auto-renewal terms will be included in Terms of Use
- [x] Cancellation instructions will be included in Support Page
- [x] Pricing clearly stated in PaywallView (buyout price + each subscription price + renewal disclosure)
- [x] Free trial terms included (7-day Live trial with auto-conversion disclosure)
- [x] Restore purchases functionality implemented (StoreKit 2 `Transaction.currentEntitlements`)
- [x] No external payment links (Guideline 3.1.1)
- [x] No price references to outside-App-Store options (paywall shows this app's prices only, no competitor price comparison)
- [x] All IAP descriptions ≤ 55 characters
- [x] All IAP display names ≤ 35 characters
- [x] IAP type purity: non-consumable buyout separated from auto-renewable subscription groups
- [x] Subscription boundary disclosed: Pro does not include Live cloud push or BYO data service
