# Capabilities Configuration — Wheel Watch

## Analysis
Based on operation guide analysis, detected requirements:
- "通知/alerts/notification" → Local + Push Notifications
- "后台刷新/BackgroundTasks" → Background Modes (BGAppRefreshTask)
- "小组件/WidgetKit/灵动岛" → Widget Extension target
- "iCloud 同步（Pro）" → iCloud (CloudKit)
- "App Group（小组件数据共享）" → App Groups
- "内购/订阅/买断/StoreKit 2" → In-App Purchase
- "Yahoo/Finnhub 行情" → Outgoing network (no special entitlement needed)
- "截图 OCR 导入 (VisionKit/PHPicker)" → No permission required (PHPicker is privacy-safe)

## Auto-Configured Capabilities
| Capability | Status | Method |
|------------|--------|--------|
| App Bundle ID → com.zzoutuo.wheelwatch | ✅ Configured | project.pbxproj (fixed from com.zzoutuo.Wheel-Watch.Wheel-Watch) |
| Deployment target unified to iOS 17.0 (project + all targets) | ✅ Configured | project.pbxproj |
| Local Notifications | ✅ Configured | UNUserNotificationCenter (no entitlement needed; runtime permission prompt) |
| Push Notifications entitlement (aps-environment=development) | ✅ Configured | `Wheel Watch/Wheel Watch.entitlements` |
| Background Modes (fetch + processing) | ✅ Configured | `Wheel Watch/Info.plist` (UIBackgroundModes) |
| BGTaskSchedulerPermittedIdentifiers = com.zzoutuo.wheelwatch.refresh | ✅ Configured | `Wheel Watch/Info.plist` |
| App Groups (group.com.zzoutuo.wheelwatch) | ✅ Configured | App + Widget entitlements |
| iCloud (CloudKit + container iCloud.com.zzoutuo.wheelwatch) | ✅ Entitlements added | `Wheel Watch/Wheel Watch.entitlements` |
| In-App Purchase | ✅ Ready | StoreKit 2 needs no entitlement; product IDs configured in PHASE 3 |
| Widget Extension target "Wheel WatchWidgets" (bundle com.zzoutuo.wheelwatch.widgets) | ✅ Created + embedded | project.pbxproj (PBXCopyFilesBuildPhase "Embed Foundation Extensions", extension point com.apple.widgetkit-extension) |
| Widget placeholder bundle compiles | ✅ Build verified | WheelWatchWidgetsBundle.swift |

## Manual Configuration Required
| Capability | Status | Steps |
|------------|--------|-------|
| App Group registration (group.com.zzoutuo.wheelwatch) in Apple Developer portal | ⏳ Pending | developer.apple.com → Identifiers → App Groups → create + attach to App & Widget App IDs (automatic signing usually creates this on first device build) |
| iCloud container registration (iCloud.com.zzoutuo.wheelwatch) | ⏳ Pending | developer.apple.com → Identifiers → iCloud Containers → create + enable CloudKit; first device build with automatic signing may auto-register |
| APNs key for Pro Live cloud push (backend) | ⏳ Pending | Create .p8 APNs key in developer portal; store as Cloudflare Worker secret when deploying backend (PHASE 4+5 generates backend/; deployment is optional manual step) |
| IAP products in App Store Connect | ⏳ Pending | Create the 4 products after PHASE 3 defines product IDs (non-consumable + 2 auto-renewable subs + consumable? none) |

**Graceful degradation**: All ⏳ items are non-blocking. The app fully works with local storage + local notifications without any portal registration; iCloud sync / APNs / IAP enhance when configured.

## No Configuration Needed
- Camera/Photo Library permission (screenshot import uses PHPicker — no permission prompt)
- Location, HealthKit, Siri, Sign in with Apple — not in guide

## Verification
- Build succeeded after configuration: ✅ (xcodebuild iPhone 16 sim, app + widget extension, BUILD SUCCEEDED)
- All entitlements correct: ✅ (built Info.plist verified: BGTaskSchedulerPermittedIdentifiers, UIBackgroundModes, CFBundleIdentifier=com.zzoutuo.wheelwatch, widget NSExtension point correct)
- Simulator cleaned up after test: ✅ (iPhone 16 C77A1FB3 erased)
