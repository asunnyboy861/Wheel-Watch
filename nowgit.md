# Git Repositories

## Main App (iOS Application)

| Item | Value |
|------|-------|
| **Repository Name** | Wheel-Watch |
| **Git URL** | git@github.com:asunnyboy861/Wheel-Watch.git |
| **Repo URL** | https://github.com/asunnyboy861/Wheel-Watch |
| **Visibility** | Public |
| **Primary Language** | Swift |
| **GitHub Pages** | ✅ **ENABLED** (from `/docs` folder) |

## Policy Pages (Deployed from Main Repository /docs)

| Page | URL | Status |
|------|-----|--------|
| Landing Page | https://asunnyboy861.github.io/Wheel-Watch/ | ✅ Active |
| Support | https://asunnyboy861.github.io/Wheel-Watch/support.html | ✅ Active |
| Privacy Policy | https://asunnyboy861.github.io/Wheel-Watch/privacy.html | ✅ Active |
| Terms of Use | https://asunnyboy861.github.io/Wheel-Watch/terms.html | ✅ Active |

## Repository Structure

```
Wheel-Watch/
├── Wheel Watch.xcodeproj/         # Xcode Project (app + widget + tests targets)
├── Wheel Watch/                   # iOS App Source Code
│   ├── Engine/                    # GreeksEngine, RuleEngine (pure, unit-tested)
│   ├── Models/                    # Position, AlertRule, EventLog (SwiftData)
│   ├── Services/                  # QuoteService, OptionChainService, EvaluationService,
│   │                              # NotificationService, PurchaseManager, BackgroundRefreshService…
│   ├── ViewModels/
│   ├── Views/                     # Home, AddPosition, Detail, RollRadar, Stats, Settings, Paywall, ContactSupport
│   ├── Wheel Watch.entitlements   # Push, App Group, iCloud
│   └── Info.plist                 # BGTaskSchedulerPermittedIdentifiers, UIBackgroundModes
├── Wheel WatchWidgets/            # WidgetKit extension (lock-screen ring + medium summary)
├── Wheel WatchTests/              # 14 unit tests (BSM standard values + rule engine)
├── capabilities.md
├── icon.md
├── improvement_plan_1.md
├── price.md
├── us.md
├── nowgit.md
├── keytext.md              # ⚠️ EXCLUDED from repo (.gitignore — confidential ASO strategy)
├── COMPETITOR_REPORT.md    # ⚠️ EXCLUDED from repo (.gitignore — confidential competitor analysis)
└── .env                    # ⚠️ EXCLUDED from repo (.gitignore — secrets)
```

## Build Verification

- iPhone 16 (iOS 26.4 simulator): BUILD SUCCEEDED + 14/14 unit tests passed
- iPad Pro 13-inch (M5, iOS 26.4 simulator): BUILD SUCCEEDED
- Simulators erased after testing (scope-safe cleanup)
