# 搜索自己的仓库与组织仓库

## 一、动机

在这次改动之前，StarLight 只能搜索 starred repositories。但日常最常需要跳转的往往是自己正在写的仓库、以及自己所在组织下的仓库——这些恰恰是搜不到的，除非你顺手 star 了自己的项目。

于是新增第二条仓库数据流：**自己拥有的仓库 + 自己所在组织下的所有仓库**，和 starred 列表合并进同一个搜索面板。

## 二、范围

### 新增（`StarLightCore`）

| 文件 | 作用 |
|------|------|
| `PersonalRepositoriesService.swift` | 新的 actor，抓取并缓存「自己的 + 组织的」仓库 |
| `PersonalRepositoriesRefreshPolicy.swift` | 该不该发起自动刷新的纯决策函数 |
| `RepositorySearchCatalog.swift` | 合并两个集合、去重、私有过滤，以及搜索词匹配 |
| `OAuthScopeSatisfaction.swift` | 判断已授予的 scope 串是否满足所需 scope（含 GitHub 的 scope 包含关系） |
| `AuthenticationFailureReporter.swift` | 从 `RepositoriesService` 抽出的认证失效判定与上报，两个 service 共用 |
| `RepositoryCacheLocation.swift` | 缓存文件路径解析 + 旧文件名迁移 |

### 重命名（消歧义）

有了第二个仓库集合之后，原来那些泛泛叫「repositories」的名字全都有歧义了：

| 旧 | 新 |
|----|----|
| `RepositoriesService` | `StarredRepositoriesService` |
| `RepositoriesRefreshPolicy` | `StarredRepositoriesRefreshPolicy` |
| `RepositoriesServiceError` | `StarredRepositoriesServiceError` |
| `AppServices.repositoriesService` | `AppServices.starredRepositoriesService` |
| `.repositoriesServiceAuthenticationFailed` | `.gitHubAuthenticationFailed` |
| `~/Documents/Repositories.json` | `~/Documents/StarredRepositories.json` |
| `~/Documents/RepositoriesMetadata.json` | `~/Documents/StarredRepositoriesMetadata.json` |

通知改名是因为它现在由两个 service 共同发出，再叫 `repositoriesService...` 就指代不清了。

**没有改名的**：`Defaults` 的 `repositoriesRefreshInterval`。这个定时器间隔现在同时驱动两个 service，名字依然准确；而且改 key 字符串会丢掉用户已有的设置。

### 修改（App 层）

- `AppServices` 增加 `personalRepositoriesService`，并在 `init` 里把已存的偏好推给两个 service
- `MainActionBarController` 搜索合并后的列表，订阅两个 service 的变更
- `MainActionBarCellView` 给私有仓库加锁图标
- `AppStatusItemController` 两个 service 任一忙碌就转菊花
- `AppRoute` 新增 `.reauthorize`；`SettingsRoute` 新增 `.reauthorize`；`SettingsCoordinator.Delegate` 新增对应回调
- `LoginRoute.login(errorMessage:)` 改为 `login(notice:)`，`LoginNotice` 区分「失败」和「提示」
- Settings 新增两个开关

## 三、关键设计与取舍

### 3.1 为什么用三个端点，而不是一个

抓取顺序（串行，避免触发 GitHub 的二级限流）：

1. `GET /user/repos?affiliation=owner,organization_member`
2. `GET /user/orgs`
3. 对每个组织 `GET /orgs/{org}/repos?type=all`

第 1 步看起来被第 3 步覆盖了，其实不是。**没有 `read:org` scope 时，`GET /user/orgs` 只返回你公开了成员身份的组织**——你把成员身份设为私密的那些组织，第 2 步根本看不见，于是第 3 步也不会去查。第 1 步的 `organization_member` 不受这个限制，正好补上这个缺口。

反过来第 3 步也不能省：`/user/repos` 的 `organization_member` 按 GitHub 的定义是「你所在的每个 team 能访问的仓库」，你不在任何 team、但组织内可见的仓库不会出现在里面。

两步都保留，按 `fullname` 去重，代价是每个组织多一轮分页请求。认证用户的速率限制是 5000 次/小时，正常账号远远用不完。

### 3.2 刷新策略：为什么不照搬 starred 那套

`StarredRepositoriesService` 的轻量探测（只拉第一页和最后一页，比对「首页仓库名 + 远端总数」就能判断成员关系变没变）在这里用不了，原因有两个：

- `/user/repos` 在 `GitHubClient` 里走的是 `requestArray`，返回的是裸数组而不是带 `lastPageNumber` 的 `PaginatedResponse`，**算不出远端总数**；
- 就算能算，探测也只覆盖第 1 步那一路，第 3 步（组织仓库）完全在探测范围之外。

所以这里改成务实策略：**每次刷新都翻完所有页，但自动刷新有 30 分钟的最小间隔**（`minimumFullRefreshInterval`）。菜单栏手动 Refresh 无视这个间隔。

代价：组织里新建了一个仓库、而你不在相关 team 上时，最多要等 30 分钟才会出现。手动 Refresh 可以立刻拿到。

另一个简化：manual 刷新不抢占正在跑的自动刷新，而是直接 join 它。因为两者做的是完全一样的事，没有「轻量 vs 完整」之分，抢占没有意义。

### 3.3 私有仓库：为什么做成可选开关

GitHub 的 OAuth App **没有只读的私有仓库 scope**。想读私有仓库只有 `repo`，而 `repo` 同时带写权限（fine-grained PAT 有更细的粒度，但那不是 OAuth 流程，做不到「点一下登录」）。

所以不能默认申请：让一个只读的搜索工具默认握着所有私有仓库的写权限，是不合适的。做法是：

- 默认 scope 仍是 `read:user` + `public_repo`——**老用户完全不受影响，不需要重新登录**
- 设置里的 `Include Private Repositories` 打开时才申请 `read:user` + `repo` + `read:org`，并弹框说明这一点，确认后走一次重新授权

`RepositoryAccessLevel` 这个 enum 把「两组 scope」封装起来，App 层只需要在两个语义值之间选，不直接碰 `OAuthScope`。

### 3.4 scope 满足性判断为什么不能比字符串

GitHub 的 scope 有包含关系：`repo` 隐含 `public_repo`，`admin:org` 经由 `write:org` 隐含 `read:org`，`user` 隐含 `read:user`。而 token 响应里的 `scope` 字段只列出**字面申请过的**那些。

如果直接做字符串比对，一个已经授予 `repo` 的用户会被要求「再授权一次以获得 `public_repo`」——明显是错的。`OAuthScopeSatisfaction` 把 GitHub 文档里的整张包含关系表建模成传递闭包来解决这个问题。

### 3.5 关掉开关后，已缓存的私有仓库怎么办

过滤放在**使用点**（`RepositorySearchCatalog.merged` 的 `includingPrivateRepositories` 参数），不放在 service 里。好处是一处生效、两个数据源都覆盖，而且开关可以瞬间生效不用重新抓取。

代价是：**关掉开关不会删除已经落盘的私有仓库缓存**。真正撤销权限要去 GitHub 的授权管理页（设置里已有那个按钮）。这一点在下面的隐私说明里再强调一次。

### 3.6 登录界面的提示语区分了失败和提示

原来 `LoginRoute.login(errorMessage:)` 只有一种提示，界面上一律红色。重新授权不是错误，用红字提示会误导用户以为出了问题。所以改成 `LoginNotice`，分 `.failure`（红）和 `.information`（次要色）两种。

## 四、影响面

### 隐私

**开启私有仓库搜索后，私有仓库的名称、描述、topic 等元数据会以明文 JSON 落在 `~/Documents/PersonalRepositories.json`。** 这和既有的 starred 缓存做法一致（同样明文），但私有仓库的敏感度更高，所以单独点出来。

仓库内容本身不会被下载，只有列表元数据。

### 缓存文件

新增两个文件：

| 路径 | 内容 |
|------|------|
| `~/Documents/PersonalRepositories.json` | 自己的 + 组织的仓库数组 |
| `~/Documents/PersonalRepositoriesMetadata.json` | authenticated user login、上次完整刷新时间 |

加上重命名后的两个 starred 文件，一共四个。

### 请求量

关掉 `Search My Repositories` 时，`PersonalRepositoriesService` 一个请求都不发（`isEnabled` 默认为 `false`，要等 App 层推入偏好才会启动）。

开启时，每轮完整刷新的请求数约为 `1（authenticatedUser） + 自己仓库的页数 + 组织列表的页数 + Σ 每个组织的页数`。

### 组织不可访问时的降级

某个组织因为 SAML 强制或组织主禁用了第三方 App 而查不了时，只跳过那一个组织（打日志），不影响其它组织和自己的仓库。但如果错误是「token 被拒绝」，仍然会正常上报并触发重新登录。

## 五、迁移 / 升级注意事项

- **老用户不需要做任何事。** 默认 scope 没变，不会被强制重新登录。starred 缓存文件会在首次启动时自动改名搬过去（`RepositoryCacheLocation.migrateLegacyStorage`），不会因为改名而重新全量抓取。
- `Search My Repositories` 默认**开**，所以升级后会多出一轮针对自己和组织仓库的抓取。只搜到公开的部分。
- `Include Private Repositories` 默认**关**。
- 如果用户开了私有开关但在 GitHub 那边取消了授权，设置页会显示一行警告和「Sign In Again」按钮；弹框里点 Cancel 会把开关自动关回去，避免开关状态和实际权限不一致。
- 代码里所有 `RepositoriesService` / `RepositoriesRefreshPolicy` 的引用都要改成 `Starred` 前缀版本，`.repositoriesServiceAuthenticationFailed` 要改成 `.gitHubAuthenticationFailed`。
