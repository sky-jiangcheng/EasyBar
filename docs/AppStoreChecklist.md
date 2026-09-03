# StatusBar Pro App Store 清单

## 当前 App Store 兼容范围

- 仅使用公共 macOS API
- 通过 `NSWorkspace.shared.runningApplications` 列出运行中的应用
- 不请求屏幕录制、输入监控、文件访问、网络访问或自动化权限
- 请求 Accessibility 权限以检测应用状态（运行中/隐藏）
- 包含最小 App Sandbox 授权文件 `Sources/StatusBar Pro/Resources/StatusBar Pro.entitlements`
- 通过 `script/build_and_run.sh` 提供本地签名 `.app` 包
- 包含占位 App Icon 资源目录 `Sources/StatusBar Pro/Resources/Assets.xcassets`

## 提交前必要步骤

1. 安装完整 Xcode 并使用 `xcode-select` 选择
2. 打开 `StatusBar Pro.xcodeproj`
3. 使用 Apple Developer 账户登录 Xcode
4. 选择 `StatusBar Pro` target，在 Signing & Capabilities 中选择你的 Team
5. 为 `com.jiangcheng.StatusBar Pro` 创建 Apple Developer App ID（或更新 bundle identifier）
6. 保持 Automatically manage signing 启用，让 Xcode 自动创建 provisioning profile
7. 确认 App Sandbox 已通过 `Sources/StatusBar Pro/Resources/StatusBar Pro.entitlements` 启用
8. 配置 Mac App Store 发布证书和 provisioning profile
9. 添加生产元数据：
   - App 图标集
   - 版本号和构建号
   - 版权字符串
   - 应用分类
   - 隐私营养标签（声明此版本仅请求 Accessibility 权限）
10. 使用 Xcode Organizer 归档、验证并上传到 App Store Connect

## 当前本地状态

- `StatusBar Pro.xcodeproj` 存在，包含 `StatusBar Pro` macOS target 和共享 scheme
- Xcode Debug 构建成功，Team `M3A6LK593A`
- Xcode Release 归档成功
- App Store Connect 导出成功，生成 `build/export/StatusBar Pro.pkg`
- 导出包使用 `Cloud Managed Apple Distribution`
- 导出 app 使用 `Team Store Provisioning Profile: com.jiangcheng.StatusBar Pro`
- App Store Connect 上传成功，包正在处理中

## 创建 App Store Connect App 记录

在 App Store Connect 中创建新的 macOS app：

- Platform: macOS
- Name: StatusBar Pro
- Bundle ID: `com.jiangcheng.StatusBar Pro`
- SKU: `easybar-001`
- User Access: Full Access

上传新构建：

```bash
env DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -exportArchive -archivePath build/StatusBar Pro.xcarchive -exportPath build/upload -exportOptionsPlist ExportOptionsUpload.plist -allowProvisioningUpdates
```

## 功能特性

### 核心功能
- App 类型自动检测（Status Bar / Dock）
- 操作按钮（Open / Quit / Force Quit）
- 实时监控运行中的应用
- 搜索过滤
- Stat Cards 统计（Total / Status Bar / Dock）

### 界面设计
- HSplitView 布局（sidebar + 详情）
- Popover 聚合面板（状态栏快速访问）
- 操作按钮（Open 🔵 / Quit 🔴 / Force Quit 🟠）

### App 类型
- **Status Bar**：仅有状态栏图标，无 Dock 图标。使用 `launchApplication` 激活。
- **Dock**：有 Dock 图标。使用 `activate` 激活。

## 重要约束

此版本有意避免全局热键，因为 App Store 安全的全局快捷键处理可能需要额外权限或额外的审查说明。已实现的快捷键在 StatusBar Pro 活动时工作：

- `Command R`：刷新运行中的应用
- `Command Shift H`：隐藏 StatusBar Pro
- `Command F`：搜索
- `Command W`：关闭窗口

## 已知限制

- Status Bar 应用无法通过 `NSRunningApplication.activate()` 激活（macOS 安全限制）
- 部分 accessory app（如 Macs Fan Control）无法被其他 app 激活
- App 类型检测基于 `activationPolicy`，无法自动检测状态栏图标
