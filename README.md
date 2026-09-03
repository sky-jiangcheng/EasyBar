# StatusBar Pro

macOS 菜单栏管理工具，自动检测并管理状态栏和 Dock 应用。

## 功能特性

### 核心功能
- **App 类型自动检测**：基于 `activationPolicy` 自动区分 Status Bar 和 Dock 应用
- **操作按钮**：一键打开、退出、强制退出应用
- **实时监控**：定时刷新运行中的应用列表
- **搜索过滤**：按名称或 Bundle ID 搜索应用

### 界面设计
- **主窗口**：HSplitView 布局，左侧 sidebar + 右侧详情
- **Stat Cards**：Total / Status Bar / Dock 统计卡片，点击联动过滤
- **Popover**：状态栏聚合面板，搜索 + 应用列表
- **操作按钮**：Open (🔵) / Quit (🔴) / Force Quit (🟠)

### App 类型
| 类型 | 说明 | 激活方式 |
|------|------|----------|
| Status Bar | 仅有状态栏图标，无 Dock 图标 | `launchApplication` |
| Dock | 有 Dock 图标 | `activate` |

## 技术栈

- **语言**：Swift 6.0
- **最低系统**：macOS 14+
- **框架**：SwiftUI + AppKit
- **架构**：`@Observable` (Observation framework)
- **构建**：Swift Package Manager

## 项目结构

```
StatusBar Pro/
├── Sources/StatusBar Pro/
│   ├── App/
│   │   ├── StatusBar ProApp.swift      # App 入口
│   │   └── StatusBarManager.swift  # 状态栏管理
│   ├── Managers/
│   │   ├── MenuBarMonitor.swift    # 核心监控逻辑
│   │   ├── SettingsStore.swift     # 设置存储
│   │   ├── AccessibilityManager.swift  # 权限管理
│   │   └── AggregationPanel.swift  # 聚合面板
│   └── Views/
│       ├── ContentView.swift       # 主窗口
│       ├── PopoverView.swift       # 状态栏面板
│       ├── SettingsView.swift      # 设置界面
│       ├── AggregationView.swift   # 聚合视图
│       └── IconOrderView.swift     # 图标排序
├── Package.swift
├── script/
│   └── build_and_run.sh
└── docs/
    ├── index.html
    ├── privacy/
    └── support/
```

## 本地运行

```bash
# 构建并运行
./script/build_and_run.sh

# 仅构建
swift build

# 运行已构建的 app
./script/build_and_run.sh run
```

## 系统要求

- macOS 14.0+
- Accessibility 权限（用于检测应用状态）

## 已知限制

- Status Bar 应用无法通过 `NSRunningApplication.activate()` 激活（macOS 安全限制）
- 部分 accessory app（如 Macs Fan Control）无法被其他 app 激活
- App 类型检测基于 `activationPolicy`，无法自动检测状态栏图标

## 版本历史

| 版本 | 内容 |
|------|------|
| v1.1.0 | Phase 1-5 完整实现 |
| v1.2.0 | Window + status bar 支持 |
| v1.3.0 | P0/P1 code review 修复 |
| v1.4.0 | AggregationPanel 可达 + iconSpacing |
| v1.5.0 | AX API 兼容性 + debug 工具 |
| v1.6.0 | 移除 AX 隐藏，纯 UI 聚合方案 |
| v1.7.0 | Quit/force-quit + App 状态检测 |
| v1.8.0 | UI 重新设计 + Sidebar 修复 |
| v1.9.0 | HSplitView 布局 + stat card 联动 |
| v1.10.0 | accessory app 检测 + eye icon 手势修复 |
| v1.11.0 | 移除 hasStatusBar 自动检测 |
| v1.12.0 | App 类型检测 + 移除 hide 功能 |
| v1.13.0 | **里程碑：Status Bar app 跳转修复** |

## CI/CD 发布（App Store）

GitHub Actions 自动构建、签名并上传到 App Store。

- **触发**：推送 `v*` 标签，或手动 `workflow_dispatch`。
- **流程**：`swift build -c release` → 组装 `.app` → 签名 → `productbuild` 打包 `.pkg` → `altool` 上传。
- **所需 Secrets**（Repo → Settings → Secrets and variables → Actions）：

| Secret | 内容 |
|--------|------|
| `APPLE_DISTRIBUTION_CERT_P12` | Apple Distribution 证书 `.p12`（base64） |
| `APPLE_DISTRIBUTION_CERT_PASSWORD` | 证书密码 |
| `APPLE_PROVISIONING_PROFILE` | Mac App Store `.mobileprovision`（base64） |
| `APP_STORE_CONNECT_API_KEY_ID` | App Store Connect API Key ID |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID |
| `APP_STORE_CONNECT_API_KEY` | `.p8` 私钥内容（base64） |

- **可选变量**：`BUNDLE_ID`（默认 `com.jiangcheng.MacStatusApp`）。

发布：

```bash
git tag v1.14.0 && git push origin v1.14.0
```

## License

MIT
