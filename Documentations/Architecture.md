# 架构总览

这份文档说明 StarLight 的整体结构：一次按下快捷键的请求怎么穿过 coordinator 树到达搜索面板，数据从哪里来、存到哪里去，以及各层之间的边界在哪。单个子系统的细节在各自的专题文档里，本文只负责把它们串起来。

## 一、分层

| 层 | 位置 | 职责 |
|----|------|------|
| App 层 | `StarLight/` | AppKit coordinator、window controller、view controller，以及 SwiftUI 视图 |
| Components 包 | `Components/` | 与 UI 无关的业务逻辑和可复用组件，拆成 4 个 target |

Components 是一个本地 Swift package，被 Xcode 工程以本地依赖方式引入。它的 `Package.swift` 里有一个 `local`/`remote` 辅助函数：本机开发时优先解析同级目录里的 `GitHubServices` 和 `CocoaCoordinator` checkout，找不到时回落到远程分支；而当这个 package 自身被当作依赖 clone 下来时（路径里含 `/checkouts/`、`/SourcePackages/` 或 `/.build/`），一律走远程，避免把开发机的绝对路径带出去。

四个 target 的边界：

- **StarLightCore** —— 业务逻辑。`LoginService`、`StarredRepositoriesService`、`PersonalRepositoriesService`、两者各自的 refresh policy、`RepositorySearchCatalog`、`RepositorySearchIndex`、`OAuthScopeSatisfaction`、`Configs`、`Keychains`。不 import 任何 UI 框架。
- **StarLightUI** —— 目前只有 `AsyncButton` 一族（一个执行 async 操作并自动呈现错误的 SwiftUI 按钮）。菜单栏和搜索面板的代码在 App 层，不在这里。
- **StarLightUtilities** —— 只有 `@UserDefault` property wrapper。
- **StarLightResources** —— SwiftGen 生成的 Octicons asset catalog 访问代码。

## 二、启动路径

`AppDelegate` 持有三样东西，`applicationDidFinishLaunching` 只是把两个 lazy 属性摸一下让它们创建出来：

```
AppDelegate
├── AppServices              // LoginService + StarredRepositoriesService + PersonalRepositoriesService
├── AppCoordinator           // 根 coordinator，lazy
└── AppStatusItemController  // 菜单栏图标，lazy，持有 router 引用
```

`AppCoordinator` 在 `init` 里决定初始路由：

- 没有 token → `.login`
- 有 token 且 `showSettingsOnLaunch` 为真 → `.settings`
- 有 token 且不显示设置 → 没有初始路由，同时把 activation policy 设成 `.accessory`（纯菜单栏，无 dock 图标）

同时注册全局快捷键（按下时 `trigger(.main)`），并监听 `.gitHubAuthenticationFailed` 通知。

## 三、Coordinator 树与路由

导航完全由 coordinator 驱动，没有 storyboard，也没有 SwiftUI `NavigationStack`。每个 coordinator 声明一个 `Route` enum 和一个 `prepareTransition(for:)`；父子之间用嵌套在 coordinator 内部的 `Delegate` protocol 通信。

```
AppCoordinator (AppRoute)
├── LoginCoordinator (LoginRoute)        // SceneCoordinator，路由时自动成为 child
├── SettingsCoordinator (SettingsRoute)  // SceneCoordinator，路由时自动成为 child
└── MainCoordinator (MainRoute)          // 被强引用持有，不是 scene
```

### 认证门控

`AppRoute` 自己声明每条路由是否需要登录：

```swift
enum AppRoute: Routable {
    case login, authenticationFailed, reauthorize, settings, main, refresh

    var requiresAuthentication: Bool { ... }  // login / authenticationFailed / reauthorize 为 false，其余为 true
}
```

`AppCoordinator.prepareTransition(for:)` 的第一步就是：如果这条路由需要认证而当前没有 token，就把它改写成 `.login`。这样菜单项、快捷键、通知等所有调用点都不需要自己判断登录状态——它们只管 `trigger`，要不要拦截由根 coordinator 统一决定。

### 各 coordinator 的职责

- **LoginCoordinator** —— `SceneCoordinator`，路由 `.login(notice:)` 展示登录窗口、`.logged` 关闭窗口并通知 delegate。展示时把 activation policy 切成 `.regular` 并激活 App。`LoginNotice` 分 `.failure`（红字）和 `.information`（次要色）两种，后者用于「请重新授权以获得更宽的 scope」这类不是错误的提示。
- **SettingsCoordinator** —— `SceneCoordinator`，路由 `.settings` / `.dismiss` / `.logout` / `.reauthorize`。`.reauthorize` 故意不关闭设置窗口（transition 是 `.none()`），只把请求通过 delegate 冒泡给 `AppCoordinator`，这样用户授权完还停在刚才操作的开关上。它额外监听自己窗口的 `willCloseNotification`：窗口关闭时把自己从 coordinator 树摘掉，并把 activation policy 切回 `.accessory`。
- **MainCoordinator** —— 只有 `.present` 和 `.cancel` 两条路由，内部持有 `MainActionBarController`。它不呈现窗口也不呈现视图，因此不参与 scene child 的生命周期，而是被 `AppCoordinator` 直接强引用。搜索面板的 controller 是它的私有实现细节，根 coordinator 只能通过这两条路由操作面板。

### 生命周期由谁负责

CocoaCoordinator 会在 routed transition 执行前把目标 coordinator 加进 child，执行完成后按窗口/视图层级自动清理，且 `addChild` 按对象身份幂等。**不要手动调用 `addChild` 或 `removeChild`** 来管理 Login 和 Settings。这一点的来龙去脉见 [认证路由与 Coordinator 生命周期重构](AuthenticationRoutingRefactor.md)。

`AppCoordinator` 在构造 Login / Settings 之前会先在 `children` 里找现有实例，找到就复用，避免重复路由创建出第二个窗口。

### 认证失效

两个 repository service 都通过共用的 `AuthenticationFailureReporter` 上报：发现 GitHub 拒绝了 token（响应 message 命中 `Bad credentials`、`Requires authentication`、`Resource not accessible by personal access token` 之一）时，清掉 Keychain 里的 token 并发出 `.gitHubAuthenticationFailed` 通知。其它错误（限流、网络抖动）不会把用户踢下线。

`AppCoordinator` 用**一条** `.authenticationFailed` 路由回应，它组合三个 transition：

1. 让 `MainCoordinator` 取消搜索面板；
2. 如果 Settings 开着，让它关闭；
3. 展示 Login，并把错误信息一路带到登录界面上。

关键点是这三件事表达为一次 route 组合，而不是散落在通知处理函数里的一串命令式调用。

## 四、服务层

`AppServices` 是一个极简 service locator，持有三个服务，通过 coordinator 逐层注入到各 view model。view model 继承自 `ViewModel<Route>`（`@MainActor`），它持有 `appServices` 和一个 unowned 的 `router`。

`AppServices.init` 还负责把已存的用户偏好推回给各 service——两个 service 都是从自己的内置默认值起步的，不推的话用户改过的刷新间隔在下次启动时会悄悄退回 15 分钟。

### LoginService

一个 actor，封装 GitHub OAuth **Device Flow**。`login()` 起一个 task 调用 `GitHubClient.deviceFlowLogin`，拿到 device code 后通过 `LoginServiceDelegate`（`@MainActor`）回传给 `LoginViewModel`；view model 收到后把 user code 复制到剪贴板并打开浏览器。轮询成功拿到 token 后写入 Keychain。

因为不再有 client secret，App 无法自己调用 `DELETE /applications/{client_id}/token` 撤销授权，所以 `logout()` 只是清本地 token，另外提供 `manageAuthorizationURL` 让用户去 GitHub 页面撤销。切换到 Device Flow 的完整背景见 [认证流程重构](AuthFlowRefactor.md)。

`login(accessLevel:)` 按 `RepositoryAccessLevel` 决定申请哪组 scope：默认的 `.publicRepositoriesOnly`（`read:user` + `public_repo`），或用户在设置里开启私有仓库搜索后的 `.includingPrivateRepositories`（`read:user` + `repo` + `read:org`）。`hasGrantedAccess(for:)` 用 `OAuthScopeSatisfaction` 判断当前 token 是否已经够用——它建模了 GitHub 的 scope 包含关系，所以一个授予了 `repo` 的 token 不会被误判为缺少 `public_repo`。

### StarredRepositoriesService

一个 actor，负责拉取、缓存和刷新 starred repositories。对外暴露两个 `@Published` 属性：

- `state`（`.idle` / `.fetching` / `.loading`）—— 菜单栏图标据此在星星和转圈之间切换；
- `repositoriesChangeIdentifier` —— 一个单调递增的计数器，面板打开时据此重新过滤当前搜索词的结果。

它的刷新策略是这个项目里最复杂的一块：初始化时先加载磁盘缓存再开网络请求；定时器到点时只探测第一页和最后一页判断成员关系有没有变；只有在成员变化、缓存为空、换了账号、距上次完整刷新满 24 小时或用户手动 Refresh 时，才串行翻完所有页。手动刷新会抢占正在跑的自动探测，但绝不让两个分页任务并发。完整设计与取舍见 [Starred Repositories 刷新优化](StarredRepositoriesRefreshOptimization.md)。

需要判断的纯逻辑抽在 `StarredRepositoriesRefreshPolicy` 里（三个静态函数：该不该完整刷新、成员关系变没变、该不该抢占正在跑的刷新）。新增决策逻辑时照这个模式走，把判断和 I/O 分开——单元测试只覆盖这类纯函数。

### PersonalRepositoriesService

另一个 actor，负责「自己拥有的 + 自己所在组织下的」仓库。`@Published` 属性和 `StarredRepositoriesService` 同构（`state` 和 `repositoriesChangeIdentifier`），所以 UI 层用同样的方式订阅。

它串行走三个端点：`GET /user/repos`（`affiliation=owner,organization_member`）、`GET /user/orgs`、再对每个组织 `GET /orgs/{org}/repos?type=all`，按 `fullname` 去重后按 `pushedAt` 降序排。第一步和第三步都不能省，原因见 [搜索自己的仓库与组织仓库](PersonalRepositoriesSearch.md)。

刷新策略比 starred 那套简单：没有轻量探测（这些端点返回裸数组，拿不到远端总数），每次都翻完所有页，靠 30 分钟的最小间隔限制自动刷新频率，手动 Refresh 无视间隔。判断函数是 `PersonalRepositoriesRefreshPolicy.shouldRefresh`。

这个 service 默认是关闭的（`isEnabled` 为 `false`），要等 `AppServices` 把用户偏好推进来才会开始工作，因此关掉设置里的开关时它一个请求都不会发。

### 搜索目录

`RepositorySearchCatalog` 是把上面两个集合合成一个搜索列表的纯函数：个人仓库在前、starred 在后，按 `fullname` 去重，并按设置过滤私有仓库。私有过滤放在使用点而不是 service 里，所以开关能立即生效、且两个数据源都覆盖。匹配和排序不在这里，见下面的「搜索匹配」。

### token 存储

`Keychains` 是 `StarLightCore` 内部的一个 enum，用 FoundationToolbox 的 `@Keychain` wrapper 存 token，`synchronizable: false` —— token 不进 iCloud keychain，只留在本机。两个 repository service 都订阅 `Keychains.$token`，token 变化时重建 `GitHubClient` 并递增 `clientGeneration`，用它作废所有在途请求的结果。`LoginService.authorizationDidChange` 把同一个信号暴露给 UI 层，设置页据此刷新「当前授权够不够」的提示。

## 五、UI 层

### 搜索面板的呈现状态机

`MainActionBarController` 用 `UIFoundation` 的 `QuickActionBar`（通过 package trait 开启），并显式维护四个状态：`idle` / `preparing(requestIdentifier:)` / `presented` / `dismissing`。

之所以需要状态机，是因为「按快捷键」这个输入可能在动画中途反复到来：

- `idle` → 起一个准备 task（读缓存决定 placeholder 文案是「Search Repositories」还是「Loading repositories...」），然后呈现；
- `preparing` → 再按一次视为取消；
- `presented` → 再按一次尝试 `resumePresentation()`，不行就关闭；
- `dismissing` → 再按一次调用 `resumePresentation()`，在同一个 panel 上**反向接续**收起动画，而不是等 `didClose` 回调后重建一个新面板。

`preparing` 状态带一个 request identifier，准备 task 完成时会先核对 identifier 是否还是当前那一次，避免过期的准备结果把面板重新拉起来。

### 搜索匹配

`RepositorySearchIndex` 负责匹配和排序，规则对齐 GitHub 网页端的 "Search stars"：只搜仓库名、description、topics（不搜 owner、language、README）；仓库名按前缀匹配（整名或其中任一个按标点和 camelCase 切出的词），description 和 topics 只匹配完整词；搜索词按空格切开后要求**每个词都命中**，但可以命中不同字段。结果按命中强度排序——名字命中压过 topic 命中压过 description 命中，同分保持传入顺序。

索引在构造时就把每个仓库的各字段切好词，因为每次按键重新切 2000+ 个仓库要 45–60ms，而查预建索引只要 1–3ms。`MainActionBarController` 在呈现面板时用 `Task.detached` 建好索引并缓存，仓库集合刷新或私有仓库开关变化时失效。完整规则和实测依据见 [仓库搜索的匹配与排序](RepositorySearchMatching.md)。

搜索只在内存中的缓存数组上做，不发网络请求。私有仓库在 cell 上带一个锁图标。

### 菜单栏

`AppStatusItemController` 继承 `StatusItemController`，用 `MenuBuilder` DSL 构建菜单（Show Main Window / Settings… / Refresh / Quit），每一项都只是 `router.trigger(...)`。它用 `Publishers.CombineLatest` 合并两个 service 的 `$state`，只要有一个不是 `.idle` 就把按钮图标换成一个 `NSProgressIndicator`。

### activation policy

App 在 `.regular`（有 dock 图标）和 `.accessory`（纯菜单栏）之间切换，切换点只有三处：

- `AppCoordinator.init` —— 有 token 且不显示设置窗口时置为 `.accessory`；
- `LoginCoordinator` / `SettingsCoordinator` 的 `completeTransition` —— 展示窗口时置为 `.regular` 并激活 App；
- `SettingsCoordinator.windowWillClose` —— 设置窗口关闭时置回 `.accessory`。

## 六、配置与持久化

用户设置全部走 `Defaults`（key 定义在 `StarLight/Settings/Settings.swift`）：`showRepositoryDescription`、`showSettingsOnLaunch`、`repositoriesRefreshInterval`、`windowWidth`、`windowHeight`、`mainAction`、`searchPersonalRepositories`、`includePrivateRepositories`。`repositoriesRefreshInterval` 同时驱动两个 repository service。`StarLightUtilities` 的 `@UserDefault` wrapper 提供另一种访问方式，把任意 `Codable` 包一层以满足 `Defaults.Serializable`，并用 `@RecursiveLock` 缓存最近一次读到的值。

落盘位置：

| 路径 | 内容 |
|------|------|
| `~/Documents/StarredRepositories.json` | starred repository 数组 |
| `~/Documents/StarredRepositoriesMetadata.json` | authenticated user login、上次完整刷新时间 |
| `~/Documents/PersonalRepositories.json` | 自己的 + 组织的 repository 数组 |
| `~/Documents/PersonalRepositoriesMetadata.json` | 同上的 metadata |
| 登录 keychain，service `com.JH.StarLight.Keychains` | GitHub access token |

前两个文件在 1.7 及更早版本叫 `Repositories.json` / `RepositoriesMetadata.json`，首次启动时由 `RepositoryCacheLocation.migrateLegacyStorage` 自动改名搬过去。

## 七、当前的几处粗糙点

这些是阅读代码时能看到的现状，记在这里避免下一个人重新发现一遍，不代表已排期：

- Keychain 的 service name 在所有 configuration 下都是硬编码的 `com.JH.StarLight.Keychains`，因此 Debug（`dev.JH.StarLight`）和 Release（`com.JH.StarLight`）两个 bundle 共用同一条 keychain 记录。
- 缓存文件写在 `~/Documents`，而不是 Application Support 或 Caches。开启私有仓库搜索后，私有仓库的元数据也会以明文 JSON 落在那里。
- `StarLightUtilities` 的 target 依赖里仍留着 `KeychainAccess`，但 token 存储已经改走 FoundationToolbox，这条依赖目前没有实际使用者。
- `Components/Sources/StarLightUI/StarLightUI.swift` 是个空文件。
- App 层没有 test bundle，测试只覆盖 `StarLightCore` 的纯函数。
