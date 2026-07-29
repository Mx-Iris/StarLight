# Starred Repositories 刷新优化

## 背景

StarLight 原先每隔 15 分钟串行拉取完整的 starred repositories 列表。GitHub REST API 每页最多返回 100 条；当账号包含数千个 stars 时，一次刷新需要几十个网络请求。旧分页逻辑还会先请求 authenticated user，并在最后一个有效页之后继续请求一个空页，导致每次自动刷新都承担完整网络成本。

## 目标

- 保持 starred repositories 成员关系最终准确。
- 避免无变化时重复拉取全部页面。
- 不使用并发分页，降低触发 GitHub secondary rate limit 的风险。
- 继续优先使用本地缓存，使 quick action bar 能立即搜索已有数据。
- 在完整刷新过程中尽早发布最新第一页，让新添加的 star 尽快可搜索。

## 设计

### 轻量变更探测

定时刷新首先请求按 star 创建时间降序排列的第一页，并从 `Link` response header 读取最后页码。若列表超过一页，再请求最后一页。通过下面两项判断成员关系是否发生变化：

1. 第一页 repository fullname 序列是否与缓存前缀一致。
2. 根据最后页码和最后一页元素数量计算出的总数是否与缓存总数一致。

成员关系未变化时直接保留当前缓存，不重写磁盘文件。一次常规定时刷新因此只需要一到两个请求。

### 串行完整刷新

以下情况执行完整刷新：

- 没有可用缓存。
- 缓存属于其他 authenticated user 或旧缓存尚未记录用户。
- 轻量探测发现成员关系变化。
- 距离上次完整刷新已经达到 24 小时。
- 用户从菜单手动触发 Refresh。

完整刷新复用已经取得的第一页，然后按照 `Link` header 中的 `next` relation 串行获取后续页面。第一页会先与现有缓存合并并发布；所有页面成功后，才用完整结果原子替换缓存。请求失败时不会用不完整结果覆盖磁盘缓存。

手动刷新优先于自动刷新。若手动刷新发生时自动轻量探测仍在执行，服务会取消自动任务，等待其当前 in-flight request 收尾，再串行启动手动完整刷新；不会让两个分页任务并发运行。若自动任务已经进入完整刷新阶段，则直接复用该任务，避免丢弃已经完成的分页进度。

服务初始化时会先加载 cache、安装 token observer 和 refresh timer，然后在 Keychain 中已有 token 时显式启动一次 refresh。该行为不依赖 token publisher 是否重放当前值；若 publisher 同时发出当前 token，已有任务去重会避免重复请求。

### 缓存格式

`Repositories.json` 继续保存原有 repository array，使尚未更新的旧版本和 downgrade 后的 App 仍能读取缓存。新的 `RepositoriesMetadata.json` companion file 保存：

- authenticated user login
- last full refresh date

加载时也兼容曾经写入 `Repositories.json` 的 envelope 过渡格式；下一次成功刷新会重新拆分为 array 和 metadata file。只有 array、尚无 metadata 的旧缓存会被视为尚未关联用户，并在下一次成功完整刷新后补齐 metadata。

> **后续变更**：加入第二个仓库集合后，这两个文件更名为 `StarredRepositories.json` / `StarredRepositoriesMetadata.json`，首次启动时由 `RepositoryCacheLocation.migrateLegacyStorage` 自动搬迁，见 [搜索自己的仓库与组织仓库](PersonalRepositoriesSearch.md)。上面「保留文件名以便 downgrade 后仍能读到缓存」的理由因此不再成立：降级到 1.7 及更早版本会读不到缓存，代价是一次完整重新抓取。上述格式兼容逻辑本身（array 与 envelope 两种格式）保持不变。

### GitHubServices 支持

本地 `GitHubServices` 新增 authenticated `/user/starred` 分页 API。它返回 repository elements、`next`/`last` page number、`ETag` 和 `304 Not Modified` 状态，并在专用后台队列完成大页 JSON 解码。旧 API 的 callback queue 约定保持不变。

StarLight 的 Components package 在本地开发时优先解析 sibling `GitHubServices` checkout，远程 `main` 继续作为其他环境的 fallback。

## 取舍

- 常规探测只判断成员关系，不持续刷新所有 repository 的 description、topics、star count 和 fork count；这些元数据通过最长 24 小时一次的完整刷新更新。
- 没有使用并发分页。完整刷新仍可能耗时，但发生频率从每 15 分钟一次降到成员变化、手动刷新或每日一次。
- `ETag` 已由 networking layer 暴露，但当前刷新策略没有持久化逐页 `ETag`。它可以作为后续优化，不影响本次请求数量下降的主要收益。

## 验证

- `GitHubNetworkingTests` 验证 GitHub `Link` header 的 `next` 和 `last` page number 解析。
- `StarLightCoreTests` 验证完整刷新时间边界、repository 总数变化和第一页成员变化判断。
- App 构建必须在 Components 使用本地 `GitHubServices` path dependency 的情况下完成。
