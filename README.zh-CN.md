<p align="center">
  <img src="docs/assets/storeswitch-icon.png" width="152" alt="StoreSwitch icon">
</p>

<h1 align="center">StoreSwitch</h1>

<p align="center">
  <a href="README.md">English</a> · <strong>简体中文</strong>
</p>

<p align="center">
  一个把多组 App Store 账号安全留在本机、需要时快速切换的原生 macOS 工具。<br>
  A native macOS utility for securely managing and switching App Store accounts.
</p>

<p align="center">
  <a href="https://github.com/jackljp/StoreSwitch/releases/latest"><img src="https://img.shields.io/github/v/release/jackljp/StoreSwitch?display_name=tag&sort=semver" alt="GitHub release"></a>
  <img src="https://img.shields.io/badge/macOS-15.0%2B-111827" alt="macOS 15+">
  <img src="https://img.shields.io/badge/SwiftUI-native-2563EB" alt="SwiftUI">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-22C55E" alt="MIT License"></a>
</p>

## 为什么做 StoreSwitch

如果你同时使用国区、美区、日区等多个 Apple ID，下载地区限定 App 时通常需要反复打开 App Store、退出、登录、输入账号密码，再处理双重认证。StoreSwitch 把这段机械流程收进一个小工具里，同时把凭据留在系统钥匙串，而不是脚本、配置文件或剪贴板。

StoreSwitch **只切换 App Store 商店账号**，不会退出或修改 macOS 的 iCloud 主账号。

## 功能

- 自由新增、编辑和删除任意数量的 App Store 账号
- 为每个账号设置名称、地区、地区代码和备注
- Apple ID 与密码只保存到 macOS 钥匙串
- 切换前二次确认，避免误退出当前商店账号
- 自动打开 App Store、退出当前账号并填写目标账号
- 双重认证、条款和安全验证交给用户手动确认
- 原生 SwiftUI 界面，Universal macOS 构建

## 安全与隐私

StoreSwitch 的设计目标是尽量缩小凭据暴露面：

- 账号名称、地区和备注保存在本机 `UserDefaults`
- Apple ID 与密码保存在 macOS Keychain
- 凭据不会写入 Git、日志、命令行参数、临时文件或剪贴板
- 自动化脚本只在进程内生成和执行
- App 本身不上传账号数据，也不包含分析 SDK

源码可审计；安全问题请参阅 [SECURITY.md](SECURITY.md)。

## 安装

### 下载 Release

1. 前往 [Releases](https://github.com/jackljp/StoreSwitch/releases/latest) 下载 `StoreSwitch-v0.2.0-macos.zip`。
2. 解压后把 `StoreSwitch.app` 移到“应用程序”或 `~/Applications`。
3. 首次启动如被 macOS 拦截，请在 Finder 中右键 App 选择“打开”。

当前公开构建尚未 Apple notarize，macOS 可能显示未验证开发者提示。也可以在确认下载来源后执行：

```bash
xattr -dr com.apple.quarantine /Applications/StoreSwitch.app
open /Applications/StoreSwitch.app
```

### 从源码安装

需要 Xcode、XcodeGen 与 macOS 15 或更高版本：

```bash
git clone https://github.com/jackljp/StoreSwitch.git
cd StoreSwitch
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodegen generate
bash scripts/install.sh
```

安装脚本优先使用本机有效的 Apple Development 身份签名。也可以通过 `STORESWITCH_SIGNING_IDENTITY` 指定证书名称或指纹；没有开发证书时会使用固定 designated requirement 的本机 ad-hoc 签名。

## 使用

1. 打开 StoreSwitch，点击“新增账号”。
2. 填写显示名称、地区、Apple ID、密码和可选备注。
3. 选择目标账号，点击“切换到这个账号”。
4. 首次切换时，到“系统设置 → 隐私与安全性 → 辅助功能”允许 StoreSwitch。
5. 如果系统询问是否允许控制“系统事件”或 App Store，请允许。
6. 如出现双重认证、条款或安全验证，在 App Store 窗口手动完成。

如果从早期 ad-hoc 签名版本升级后遇到钥匙串 `-25293`，点击编辑或再次切换，重新输入一次 Apple ID 和密码并保存即可。StoreSwitch 0.2 已加入恢复流程。

## 构建与测试

```bash
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
xcodegen generate
xcodebuild -project StoreSwitch.xcodeproj -scheme StoreSwitch \
  -destination 'platform=macOS' \
  -derivedDataPath /tmp/storeswitch-derived-data \
  CODE_SIGNING_ALLOWED=NO test
```

生成 Release 压缩包：

```bash
bash scripts/package-release.sh
```

产物写入 `dist/`，公开构建使用固定 designated requirement 的 ad-hoc 签名，不包含维护者的开发证书身份；它仍然不是 Apple notarized 构建。

## 工作原理

StoreSwitch 读取所选账号的 Keychain 凭据，在内存中渲染 AppleScript，并通过 macOS Accessibility API 操作 App Store 菜单与登录窗口。真实密码不会成为 shell 参数或磁盘上的脚本文件。

App Store 大版本更新可能改变辅助功能层级。如果菜单或登录窗口结构发生变化，请提交 Issue，并附 macOS/App Store 版本和不含账号信息的错误文本。

## 项目结构

```text
StoreSwitch/
├── Resources/                  # App icon 与 AppleScript 资源
├── Sources/                    # SwiftUI、Keychain、状态与自动化
├── Tests/                      # 凭据隔离、恢复与模板测试
├── docs/assets/                # README 图标资源
├── scripts/install.sh          # 本机构建、稳定签名与安装
├── scripts/package-release.sh  # Release 打包
└── project.yml                 # XcodeGen 工程定义
```

## 当前限制

- 仅支持 macOS 15+
- 只切换 App Store，不切换 iCloud、Apple Music 或媒体与购买项目的其它入口
- 双重认证、验证码、条款与安全验证不能自动跳过
- 自动化依赖 App Store 的辅助功能元素，系统大版本升级后可能需要适配
- 当前 Release 未 notarize

## Roadmap

- Developer ID 签名与 notarization
- 自动检测当前 App Store 登录状态
- 凭据导出/导入时的端到端加密方案
- 更多语言与可访问性优化

## 贡献

Issue 与 Pull Request 都欢迎。提交代码前请确保不包含真实 Apple ID、密码、Keychain 导出、日志中的凭据或个人截图。详见 [CONTRIBUTING.md](CONTRIBUTING.md)。

## License

[MIT](LICENSE) © 2026 jackljp

Apple、macOS、App Store 与 Apple ID 是 Apple Inc. 的商标。StoreSwitch 是独立开源项目，与 Apple Inc. 无隶属或背书关系。
