# 认证路由与 Coordinator 生命周期重构

## 动机

StarLight 原先由根 coordinator 手动维护 Login、Settings 和 Main 的 child 关系。认证失效时，`handleAuthenticationFailed` 同时关闭窗口、修改 delegate、直接访问 Main 的 controller、手动移除 child，并通过阻塞式 alert 再进入登录流程。这让认证策略、窗口生命周期和具体 UI 实现耦合在同一个函数中。

此外，CocoaCoordinator 虽然会自动维护 transition `presentables` 中的 child coordinator，但 `.route(on:to:)` 没有把 routed coordinator 本身放入 `presentables`，导致 `SceneCoordinator` 仍需由调用方手动注册。

## 设计

### CocoaCoordinator

- `.route(on:to:)` 会在目标 coordinator 同时符合 `Presentable` 时，将其加入 routed transition 的 `presentables`。
- `addChild` 按对象身份保持幂等，重复路由到同一个可见 coordinator 不会产生重复 child。
- `AppCoordinator`、`SceneCoordinator` 和 `ViewCoordinator` 继续在 transition 执行前自动添加 child，并在执行完成后根据视图或窗口层级自动清理。

### StarLight

- 根 `AppCoordinator` 改为继承 `CocoaCoordinator.AppCoordinator<AppRoute>`。
- Login 和 Settings 均通过 routed transition 自动加入 coordinator tree，不再手动调用 `addChild` 或 `removeChild`。
- `MainCoordinator` 由根 coordinator 的强引用持有；它不是窗口或视图 presentable，因此无需进入 scene child 生命周期。
- `quickActionBarController` 保持为 `MainCoordinator` 的私有实现细节。根 coordinator 只能通过 `MainRoute.present` 和 `MainRoute.cancel` 控制主面板。

## 认证失效流程

`RepositoriesService`（后来更名为 `StarredRepositoriesService`，判定与上报逻辑也抽到了共用的 `AuthenticationFailureReporter`，见 [搜索自己的仓库与组织仓库](PersonalRepositoriesSearch.md)）清除无效 token 后发送认证失效通知。notification handler 只触发 `AppRoute.authenticationFailed`，该 route 使用组合 transition 顺序执行：

1. 通过 `MainRoute.cancel` 关闭 quick action bar。
2. 若 Settings scene 正在显示，通过 `SettingsRoute.dismiss` 关闭窗口，但不触发用户主动 logout 的 delegate 回调。
3. 复用或创建 Login scene，并在登录页面内显示 token 已失效的说明。

该流程不再弹出阻塞主线程的 modal alert，也不再从根 coordinator 访问任何子 coordinator 的私有 controller。

## 影响与迁移

- CocoaCoordinator 必须包含 routed coordinator 传播修复；StarLight 开发环境通过本地 package 路径使用该源码，远端回退指向 `main`。
- 后续新增 scene route 时，只需返回包含对应 `SceneCoordinator` 的 routed transition，不要额外手动维护 child。
- 单纯关闭 Settings 使用 `SettingsRoute.dismiss`；只有用户主动退出登录时才使用 `SettingsRoute.logout`。

## 验证

- CocoaCoordinator package tests 覆盖 routed scene coordinator 的 presentable 传播和重复 child 注册幂等性。
- StarLight 使用官方 Xcode MCP 构建，确认本地 CocoaCoordinator 源码参与编译。
