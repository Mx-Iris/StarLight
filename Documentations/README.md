# 文档索引

StarLight 的设计与演进记录。这些是面向维护者的内部文档，用中文书写；对外的说明（`README.md`、`ReleaseNotes/`、`AGENTS.md`）一律用英文。

**新增或重命名任何文档，都要在这份索引里同步登记。**

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
| [ReleaseCI.md](ReleaseCI.md) | 发布流程：GitHub Actions 如何签名、公证、打包并发布 Release，本地怎么用同一份 `scripts/release.sh` 跑，以及 release notes 的硬性前置条件。 |
