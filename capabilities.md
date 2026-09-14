# Wheel Watch — 配置文档

生成时间：2026-09-15

---

## 一、⚠️ 手动配置（增强功能 — 不配置不影响基本使用）

> **重要说明**：以下配置项均为**增强功能**。App 已通过优雅降级设计，不配置任何一项，用户下载后即可正常使用全部核心功能（本地监控、红绿灯卡片、本地通知、3 个仓位）。配置后可获得增强体验。

### 🟡 Capabilities 增强配置

#### 1. App Group 注册（Widget 小组件数据共享）

**增强功能**：锁屏倒计时环小组件、中号摘要小组件显示真实持仓数据
**不配置的影响**：小组件显示占位内容（"Add your first CSP"），App 本体完全正常
**当前状态**：App 已内置优雅降级，无需配置即可正常使用

**已自动配置部分**：
- ✅ App 与 Widget 两个 target 的 .entitlements 中已添加 `group.com.zzoutuo.wheelwatch`
- ✅ 代码已实现优雅降级（AppGroupSnapshot.swift 读取失败时小组件显示占位文案）

**如需启用增强功能，请手动配置**：
1. 打开 [Apple Developer](https://developer.apple.com) → **Certificates, Identifiers & Profiles** → **Identifiers**
2. 点击 **"+"** → 选择 **App Groups** → 填写 Description: `Wheel Watch Widgets`，Identifier: `group.com.zzoutuo.wheelwatch` → Register
3. 回到 **Identifiers** → 选择 **App IDs** → 找到 `com.zzoutuo.wheelwatch` → 编辑 → 勾选 App Groups 并选中刚创建的组 → Save
4. 对 `com.zzoutuo.wheelwatch.widgets`（Widget 扩展 App ID）重复第 3 步
5. ⚠️ 实际上，直接用 Xcode 在真机/模拟器上 Build 一次（Automatic Signing 已配置 DEVELOPMENT_TEAM=JP4TN5PTS3），Xcode 通常会自动注册 App Group — 若 Build 无报错则本项已完成

#### 2. iCloud CloudKit 容器注册（Pro 跨设备同步）

**增强功能**：Pro 用户开启 iCloud Sync 后持仓跨设备同步
**不配置的影响**：仅使用本地存储（SwiftData），App 完全正常，数据不跨设备
**当前状态**：iCloud Sync 开关默认关闭，需 Pro + 手动开启 + 重启生效

**已自动配置部分**：
- ✅ entitlements 已添加 CloudKit 服务与容器 `iCloud.com.zzoutuo.wheelwatch`
- ✅ 代码已实现优雅降级（Wheel_WatchApp.swift：无 iCloud 身份或创建失败时回退本地容器）

**如需启用增强功能，请手动配置**：
1. [Apple Developer](https://developer.apple.com) → **Identifiers** → App IDs → `com.zzoutuo.wheelwatch`
2. 编辑 → 勾选 **iCloud**（勾选 Include CloudKit support）→ 编辑容器列表 → **"+"** 创建 `iCloud.com.zzoutuo.wheelwatch` → Save
3. [CloudKit Console](https://icloud.developer.apple.com) 首次部署 Schema（真机运行 App 后 Studio 中 Push Schema）
4. ⚠️ 同上，Xcode Automatic Signing 首次真机构建通常可自动注册容器 — 若 Build 无报错则本项已完成

#### 3. APNs Key + 云推送后端部署（Wheel Watch Live 订阅服务，完全可选）

**增强功能**：Live 订阅用户获得服务器级每分钟评估 + APNs 秒级真推送
**不配置的影响**：Live 订阅在 App 内不可用（Paywall 产品将无法购买，除非先在 ASC 创建产品），免费/Pro 功能完全不受影响
**当前状态**：后端评估器代码为参考实现，未部署

**配置步骤（如需上线 Live 订阅）**：
1. [Apple Developer](https://developer.apple.com) → **Keys** → 创建 APNs Auth Key（.p8），记下 Key ID 与 Team ID
2. 部署 Cloudflare Worker：参考仓库中 backend/ 评估器（复刻 RuleEngine 逻辑），将 .p8 存入 `wrangler secret`
3. App Store Server API 订阅校验定时任务（每 24h）按 guide 第 7.5 节接入
4. ⚠️ 若暂不上线 Live：建议在 App Store Connect 暂不创建 live.* 产品，或先只上 Pro 买断

---

### 🔵 IAP StoreKit 配置（必需 — 否则无法购买）

**影响功能**：不创建 IAP 产品，用户无法购买 Pro（免费层仍完全可用）
**代码已就绪**：PurchaseManager.swift（StoreKit 2，5 个产品 ID 与 price.md 一致）、PaywallView（含 EULA/Privacy 链接 + 自动续订披露）、Restore Purchases

**配置步骤**：
1. 登录 [App Store Connect](https://appstoreconnect.apple.com) → 你的 App → **Monetize** → **In-App Purchases**
2. 创建非消耗型产品（Pro 买断）：

| 产品 | Reference Name | Product ID | 价格 |
|------|---------------|-----------|------|
| Pro 买断 | Wheel Watch Pro | `com.zzoutuo.wheelwatch.pro.onetime` | $34.99（首月早鸟可设 $24.99） |
  - Display Name: `Wheel Watch Pro`（15 字符）
  - Description: `One-time Pro unlock: all features, forever`（42 字符）

3. 创建订阅组 **Wheel Watch Live**，组内 2 个产品：

| 产品 | Reference Name | Product ID | 价格 |
|------|---------------|-----------|------|
| Live 月付 | Wheel Watch Live Monthly | `com.zzoutuo.wheelwatch.live.monthly` | $4.99/月 |
| Live 年付 | Wheel Watch Live Annual | `com.zzoutuo.wheelwatch.live.yearly` | $29.99/年（7 天免费试用，年付设为默认推荐） |

  - Display Name / Description 从 `price.md` 复制（已验证 ≤35/≤55 字符）

4. 创建订阅组 **Wheel Watch Data**，组内 2 个产品：

| 产品 | Reference Name | Product ID | 价格 |
|------|---------------|-----------|------|
| BYO 月付 | Wheel Watch BYO Data Monthly | `com.zzoutuo.wheelwatch.byo.monthly` | $1.99/月 |
| BYO 年付 | Wheel Watch BYO Data Annual | `com.zzoutuo.wheelwatch.byo.yearly` | $14.99/年 |

5. ⚠️ 创建后产品进入 "Waiting for Review" 状态，需随 App 版本一起提交审核
6. 本地测试：Xcode 中 File → New → File → StoreKit Configuration File，按上表添加 5 个产品，Scheme → Run → Options 选择该配置文件即可沙盒测试购买/恢复流程

---

### 🟢 App Store Connect 审核信息配置

**影响功能**：不配置会增加审核沟通成本
**配置步骤**：
1. App Store Connect → 你的 App → **App Review Information**
2. 在 **Notes** 字段粘贴 `keytext.md` 中 "## Review Notes" 一节的内容（含订阅产品 ID、合规声明、"Informational only - not investment advice" 说明）
3. **Privacy Policy URL** 填：`https://asunnyboy861.github.io/Wheel-Watch/privacy.html`
4. **Terms of Use (EULA) URL** 填：`https://asunnyboy861.github.io/Wheel-Watch/terms.html`（订阅类 App 必填）
5. **Support URL** 填：`https://asunnyboy861.github.io/Wheel-Watch/support.html`
6. 本 App 无 Demo Account 需求（无需登录、无需 API Key 即可使用全部免费功能）

---

## 二、✅ 自动配置记录（已由系统完成，无需操作）

### Capabilities 自动配置

| Capability | 说明 | 状态 |
|------------|------|------|
| 本地通知 | UNUserNotificationCenter + 权限引导 + 去重/合并/静默时段 | ✅ 已配置 |
| Background Modes | UIBackgroundModes (fetch/processing) + BGTaskSchedulerPermittedIdentifiers 已写入 Info.plist | ✅ 已配置 |
| WidgetKit 扩展 | Wheel WatchWidgets target 已创建并嵌入 App，含锁屏环 + 中号摘要 | ✅ 已配置 |
| App Group entitlements | App + Widget entitlements 已写入（portal 注册见手动配置） | ✅ entitlements 已配置 |
| iCloud entitlements | CloudKit + 容器声明已写入（portal 注册见手动配置） | ✅ entitlements 已配置 |
| Push entitlements | aps-environment (development) 已写入 | ✅ 已配置 |
| In-App Purchase | StoreKit 2 无需 entitlement，PurchaseManager 已实现 5 产品 | ✅ 已配置 |
| Outgoing Network Connections | HTTPS 出站（Yahoo/Finnhub/反馈后端），无需特殊权限 | ✅ 已配置 |

### 后端服务

| 服务 | 说明 | 状态 |
|------|------|------|
| 联系客服后端 | Cloudflare Workers（feedback-board），地址已硬编码于 ContactSupportView | ✅ 已部署 |
| 行情数据 | Yahoo Finance v8 主源 + Finnhub 备源（可选 BYO Key）+ 离线降级 | ✅ 免费无密钥 |
| 云推送后端 | Cloudflare Worker 评估器（backend/） | ⏳ 可选，见手动配置第 3 项 |

### 代码生成

| 模块 | 说明 | 状态 |
|------|------|------|
| 核心功能 | MVVM 架构 26 个 Swift 文件（Engine/Models/Services/ViewModels/Views） | ✅ 已完成 |
| GreeksEngine | BSM 定价 + 五 Greeks + IV 二分法，14/14 单测通过（delta 误差 <0.02） | ✅ 已验证 |
| ContactSupportView | 7 主题磁贴、必填校验、后端 POST、隐私微调文案、成功/失败反馈 | ✅ 已完成 |
| SettingsView | 政策页链接、客服入口、预设切换、规则编辑器、BYO Key（Keychain） | ✅ 已完成 |
| PurchaseManager | StoreKit 2 + currentEntitlement 反应式绑定 + 事务监听 | ✅ 已完成 |
| PaywallView | 买断 + 双订阅组 + 法务链接 + 自动续订披露 | ✅ 已完成 |
| QA 迭代 | Step 11 循环 1 轮修复 12 项问题，improvement_plan_1.md | ✅ 已完成 |
| AI Module | 不适用（AI_FEATURE_NEEDED=no） | N/A |

### 部署

| 项目 | 说明 | 状态 |
|------|------|------|
| GitHub 仓库 | https://github.com/asunnyboy861/Wheel-Watch（SSH 推送） | ✅ 已完成 |
| GitHub Pages | /docs 4 页已部署 + Actions workflow | ✅ 已启用 |
| Landing Page | 黑底荧光绿主题，App Store ID 为占位符（上架后替换） | ✅ 已完成 |
| App Store 元数据 | keytext.md 全部验证通过（Subtitle 19/30，Keywords 97/100） | ✅ 已生成 |
| 定价配置 | price.md（4 层定价 + 5 产品 ID，字符限制验证通过） | ✅ 已完成 |

---

## 三、能力检测详情

> 以下为 PHASE 2 原始检测数据。"Auto-Configured" 与 "Manual Required" 内容已重组至上方 Section 一/二。

### Analysis

基于操作指南关键词检测：
- "通知/alerts" → 本地 + 推送通知
- "后台刷新/BackgroundTasks" → Background Modes（BGAppRefreshTask）
- "小组件/WidgetKit/灵动岛" → Widget 扩展 target
- "iCloud 同步（Pro）" → iCloud (CloudKit)
- "App Group" → App Groups
- "内购/订阅/买断/StoreKit 2" → In-App Purchase
- "Yahoo/Finnhub 行情" → 出站网络（无需特殊 entitlement）
- "截图 OCR（VisionKit/PHPicker）" → 无需权限

### No Configuration Needed

- 相机/相册权限（截图导入使用 PHPicker，无权限弹窗）
- 定位、HealthKit、Siri、Sign in with Apple — 指南未涉及

### Verification

- xcodebuild iPhone 16 模拟器（iOS 26.4）：BUILD SUCCEEDED（App + Widget 扩展）
- 单元测试 14/14 通过（BSM 标准值 + 规则引擎全指标）
- App 实机启动验证通过（Home UI 渲染正常）
- 构建产物 Info.plist 验证：BGTaskSchedulerPermittedIdentifiers、UIBackgroundModes、Bundle ID、Widget NSExtension 均正确
- 模拟器已按 scope-safe 规则清理
