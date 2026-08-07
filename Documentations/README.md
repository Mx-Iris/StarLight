# 文档索引

StarLight 的设计与演进记录。这些是面向维护者的内部文档，用中文书写；对外的说明（`README.md`、`ReleaseNotes/`、`AGENTS.md`）一律用英文。

**新增或重命名任何文档，都要在这份索引里同步登记。**

> **项目类型：App（macOS）**。提案的「影响」一节关注用户可见变化、可发现性、
> 数据与配置兼容、平台与最低版本、发布流程，不涉及 ABI。
> 第一篇提案由 `/evolution <描述>` 创建时会自动建立 `Evolutions/` 目录与提案索引。

## 总览

| 文档 | 内容 |
|------|------|
| [Architecture.md](Architecture.md) | 架构总览：分层、coordinator 树与路由、服务层、UI 呈现状态机、持久化位置。想快速上手先读这篇。 |

## 专题

| 文档 | 内容 |
|------|------|
| [AuthFlowRefactor.md](AuthFlowRefactor.md) | 认证从 OAuth Web Flow 切到 Device Flow 的动机、改动范围和取舍（目标版本 v1.7）。解释了为什么不再有 client secret，以及"多设备只能登一台"问题是怎么消失的。 |
| [AuthenticationRoutingRefactor.md](AuthenticationRoutingRefactor.md) | 认证失效处理与 coordinator 生命周期的重构：认证门控为什么收敛到根 coordinator，以及为什么不该再手动 `addChild` / `removeChild`。 |
| [StarredRepositoriesRefreshOptimization.md](StarredRepositoriesRefreshOptimization.md) | starred repositories 刷新策略：轻量成员探测、串行完整刷新、手动刷新抢占规则，以及缓存文件格式的兼容处理。 |
| [PersonalRepositoriesSearch.md](PersonalRepositoriesSearch.md) | 搜索自己的仓库与组织仓库：为什么要三个端点、为什么私有仓库做成可选开关（GitHub 没有只读的私有仓库 scope）、以及一批消除歧义的重命名。 |
| [RepositorySearchMatching.md](RepositorySearchMatching.md) | 搜索栏的匹配与排序规则：GitHub 网页端 "Search stars" 的实测行为、本地复刻时的两处偏离（不搜 owner、CJK 退回子串），以及为什么必须预建索引。 |
| [ReleaseCI.md](ReleaseCI.md) | 发布流程：GitHub Actions 如何签名、公证、打包并发布 Release，本地怎么用同一份 `scripts/release.sh` 跑，以及 release notes 的硬性前置条件。 |
