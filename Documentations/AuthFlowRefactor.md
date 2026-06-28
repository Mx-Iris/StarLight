# 认证流程重构：从 OAuth Web Flow 切换到 Device Flow

> 状态：已落地，目标版本 v1.7
> 涉及仓库：`Mx-Iris/StarLight`、`Mx-Iris/GitHubServices`

## 背景与动机

v1.6 及之前的 StarLight 使用 GitHub OAuth Web Application Flow 完成登录：

```
ASWebAuthenticationSession → 浏览器同意 → 重定向 starlight:// → 用 (client_id, client_secret, code) 换 access_token
```

这个方案在实际使用中暴露了两个问题：

1. **"多设备只能登一台"的体感**。GitHub OAuth App 每次走 `/login/oauth/access_token` 都会生成一个新的 access token；同一对 `(user, application, scope)` 的活跃 token 上限为 10，超过后最旧的会被自动撤销。叠加 `prefersEphemeralWebBrowserSession = true` 导致每次登录都强制重新授权，导致开发期间 / 多设备 / 重装 App 等场景里 10 个名额很快被耗尽，体感上就是"另一台设备一登录原来那台就被踢了"。
2. **`client_secret` 必须打进二进制并随源码进入公开仓库**。StarLight 仓库是公开的，老的 secret `05cb9608…62c` 在 git 历史里暴露已超过 18 个月，存在被滥用的风险。

OAuth Device Flow 是 GitHub 为没有 redirect 回调能力的客户端（CLI、IoT、Menu Bar App）设计的授权方式，它有三个直接收益：

- **不需要 `client_secret`**，从根本上消除 secret 暴露问题。
- 每台设备走完整 Device Flow 拿到的是 GitHub 那边独立的一条 token，互不干扰，多设备并存更自然（仍受 10 个名额的 GitHub 全局滚动上限约束，但日常 1–3 台设备完全不会撞到）。
- 不再依赖 redirect URL Scheme，Info.plist 里的 `starlight://` 注册可以一并清理。

## 改动范围

### `Mx-Iris/GitHubServices`

新增 Device Flow 支持，沿用现有 `@AddAsyncAllMembers` 宏自动生成 async 版本：

- `Sources/GitHubModels/DeviceCode.swift` —— `device_code / user_code / verification_uri / expires_in / interval` 的 Codable 模型。
- `Sources/GitHubNetworking/Client/DeviceFlowError.swift` —— 覆盖 GitHub 文档列出的全部 OAuth error code（`authorization_pending` / `slow_down` / `expired_token` / `access_denied` / `unsupported_grant_type` / `incorrect_client_credentials` / `incorrect_device_code` / `device_flow_disabled` + `.other(code:description:)`），并实现 `LocalizedError`。
- `Sources/GitHubNetworking/Client/GitHubClient.swift` 加入四个静态方法：
  - `requestDeviceCode(clientID:scopes:completion:)` —— `POST https://github.com/login/device/code`。
  - `pollDeviceAccessToken(clientID:deviceCode:completion:)` —— `POST https://github.com/login/oauth/access_token`，单次轮询。
  - `deviceFlowLogin(clientID:scopes:onUserCode:completion:)` —— 高层封装，内部自动按 `interval` 轮询，命中 `slow_down` 退避 +5 秒，超过 `expires_in` 整体报 `.expiredToken`。`onUserCode` 在第一腿成功后回调，给 UI 显示 user_code。
  - `revokeAppToken(clientID:clientSecret:accessToken:completion:)` —— `DELETE /applications/{client_id}/token`。StarLight 不使用此 API（无 secret），但保留给其它消费方。

### `Mx-Iris/StarLight`

- `Components/Sources/StarLightCore/Configs.swift` —— 删除 `urlScheme` / `githubLoginURL` / `githubSecrets`，仅保留 `githubID` 和 `githubScopes`。
- `Components/Sources/StarLightCore/LoginService.swift` —— 完全重写：
  - 不再持有 `ASWebAuthenticationSession`，转而调用 `GitHubClient.deviceFlowLogin(...)`。
  - 引入 `@MainActor` 的 `LoginServiceDelegate`，在拿到 device code 后通过 `loginService(_:didReceiveDeviceCode:)` 通知 UI。
  - 新增 `cancelLogin()`，对应 UI 上的 Cancel 操作。
  - `logout()` 回归同步 `nonisolated`，仅清本地 Keychain，**不调用远端 revoke**；同时提供 `manageAuthorizationURL` 静态属性指向 `https://github.com/settings/connections/applications/<client_id>`，给 UI 一个"去 GitHub 手动撤销"的入口。
- `StarLight/Login/LoginViewModel.swift` —— `@MainActor`，发布 `deviceCode / isAuthorizing / errorMessage`；`startLogin()` 调用 `loginService.login()`，收到 device code 后自动 `NSPasteboard` 复制 user code 并 `NSWorkspace.shared.open(verification_uri)`；`cancelLogin()` 取消轮询。
- `StarLight/Login/LoginViewController.swift` —— 登录界面三态：未开始（"Sign in with GitHub" 按钮）/ 拿码中（spinner）/ 已拿码（大字号等宽 user code、"Open GitHub again"、"Cancel"、底部"Waiting for you to authorize…" spinner）。
- `StarLight/Settings/SettingsViewController.swift` & `SettingsViewModel.swift` —— Settings 底部新增 "Manage Authorizations on GitHub" 按钮，点击打开 `manageAuthorizationURL`，代替我们丢掉的远端 revoke 功能。
- `StarLight/Info.plist` —— 删掉 `CFBundleURLTypes` 整段（之前注册的 `starlight://` Scheme 在 Device Flow 下不再被使用）。
- `StarLight.xcodeproj` —— `MARKETING_VERSION` 1.6 → 1.7。

## 迁移注意点

### 上线前的 GitHub OAuth App 配置

1. **必须先勾选 "Enable Device Flow"**：打开 [github.com/settings/developers](https://github.com/settings/developers) → 选择 StarLight → 勾选页面底部的 *Enable Device Flow* → *Update application*。未勾选时，`requestDeviceCode` 返回 `DeviceFlowError.deviceFlowDisabled` 或 `.unsupportedGrantType`。
2. **不再需要 client secret**。OAuth App 仍要求至少一个有效 secret 存在，但 StarLight 客户端不会读取。

### 老用户兼容

- v1.6 及更早版本仍走 Web Flow，依赖 `client_secret` 才能完成"用 code 换 token"。**在所有用户更新到 v1.7 之前，不要在 GitHub 上 Delete 老的 client_secret**，否则老版本用户的重新登录会失败（已登录用户的 token 仍可用于 API 调用，因为日常请求不使用 secret，但任何重登行为都会被打断）。
- v1.7 发布后，建议在 Release Notes 中明确说明用户必须更新；待预计的更新周期过去后再 Reset 老 secret。
- 用户从 v1.6 升级到 v1.7 后，原 Keychain 里的 token 仍然有效，**无需重新登录**。

### Info.plist URL Scheme 清理

`starlight://` URL Scheme 在 v1.7 中已被移除。若有第三方工具或 Shell 脚本以 `open starlight://...` 形式与 StarLight 联动，会失效。本项目无此类外部集成。

### 远端 revoke 能力的取舍

为了让客户端彻底不持有 secret，本次重构放弃了"logout 时主动调用 `DELETE /applications/{client_id}/token`"。代价是 logout 后这一条 token 仍占 GitHub 10-token 滚动上限里的一个名额，直到被新登录挤出或用户在 [github.com/settings/applications](https://github.com/settings/applications) 手动撤销。考虑到日常 1–3 台设备的使用强度，这个代价可以忽略；Settings 中新增的 "Manage Authorizations on GitHub" 入口提供了手动撤销的便捷路径。

## 验证

- `swift build` 在 `Components/` 与 `GitHubServices/` 两侧均通过，0 警告。
- `xcodebuild -workspace StarLight.xcworkspace -scheme StarLight -configuration Debug build` 通过，0 警告 0 错误。
- 手工验证流程：
  1. 删除本地 Keychain 中的 StarLight token。
  2. 启动 v1.7，点 *Sign in with GitHub*。
  3. 确认浏览器自动打开 `github.com/login/device` 且剪贴板已含 user code。
  4. 在浏览器中粘贴 user code 并授权，确认 App 登录窗口自动关闭、主功能可用。
  5. 在第二台机器上重复 1–4 步，确认两台机器的 token 可并存。
