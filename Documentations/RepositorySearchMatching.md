# 仓库搜索的匹配与排序

快捷搜索栏输入一个词之后，哪些仓库算命中、按什么顺序排——这篇讲这套规则是怎么定的，以及为什么要预建索引。

## 动机

改之前的匹配规则是一句 `localizedCaseInsensitiveContains`，对 name、fullname、description、language、topics 五个字段做**任意位置子串**匹配，命中的结果不排序，直接按缓存顺序给出去。

在 2000+ 星标的账号上这套规则基本不可用：

- 搜 `board` 会把所有 `Clipboard` 相关仓库全捞出来
- 搜 `swift` 会返回 1200 多条（每个 Swift 项目都中招），而想要的那个可能在第 300 位
- 搜 `sindresorhus` 会列出他名下所有仓库

问题不在"搜不到"，而在"搜到太多且不排序"——对一个按快捷键呼出、期望两三个字符就锁定目标的启动器来说，这等于没有搜索。

参照物选了 GitHub 网页端自己的 "Search stars" 搜索框：它在同一批数据上的表现明显更准。所以先把它的实际行为测出来，再在本地复刻。

## GitHub 网页端的实际行为（实测结论）

GitHub 没有公开这套规则，以下全部是在一个 2.2k 星标的真实账号上逐条试出来的。

**只搜三个字段：仓库名（不含 owner）、description、topics。**

| 排除项 | 验证方式 |
|--------|----------|
| owner | 搜 `sindresorhus` → 0 条，尽管该账号 star 了他多个仓库 |
| language | 搜 `makefile`、`roff` → 均 0 条 |
| README | 搜 `homebrew` → 仅 5 条；若搜 README，装机说明里带 `brew install` 的至少几百条 |

**两个字段，两套匹配规则：**

| 字段 | 规则 | 实测证据 |
|------|------|----------|
| 仓库名 | 按标点和 camelCase 切词，整名或任一词做**前缀**匹配 | `clip` 命中 `Clipy` / `Clipchop` / `Mac-Finder-Clipboard` / `CLIProxyAPI`；`board` 命中 `BulletinBoard`（`Bulletin` + `Board`）但**不**命中 `Mac-Finder-Clipboard` |
| description / topics | **完整词**匹配，不做前缀 | `clipboard` 命中描述含 "clipboard history" 的仓库，`clip` 不命中；`missio` 不命中描述里的 "Mission Control" |

**多词是 AND**，且各词可以经由不同字段命中：`clipboard swift` 的结果是两个词各自结果集的交集。

**排序随查询切换**：无查询时按 "Recently starred"；一旦有查询就换成相关度排序——搜 `swift` 时首位是 `swiftlang/swift`，而不是最近 star 的那个。

## 本地实现的取舍

### 匹配规则：照搬，只有两处偏离

**偏离一：owner 明确不参与匹配。** GitHub 也不搜 owner，本地曾考虑作为低权重命中保留，最终去掉——owner 登录名很少能被准确拼出来，为它付出的误命中不划算。这也是相对旧实现唯一"变窄"的地方：以前搜 `sindresorhus` 能列出他的全部仓库，现在不能。

**偏离二：不用空格分词的语言退回子串匹配。** 中文 description 对任何基于空白的分词器都是一整串，完整词匹配会让它彻底搜不到（搜"一键"命中不了"一键开启完整"）。因此查询词含 CJK 字符时，description 和 topics 改用子串包含。GitHub 用 CJK 分析器达到同样效果，本地搜索不需要做到那个程度。

### 排序：分档打分，同分保持原序

每个查询词按命中字段取一个分值，多个查询词求和：

| 命中方式 | 分值 |
|----------|------|
| 仓库名完全相等 | 100 |
| 仓库名整串前缀 | 80 |
| 仓库名中某个词的前缀 | 60 |
| topic 完整词 | 40 |
| description 完整词 | 20 |

分值本身不重要，重要的是档位之间的间隔——名字命中必须永远压过 description 命中。

**同分保持输入顺序**，这是排序能安全套用在现有列表上的前提：传进来的顺序本身有意义（自己的仓库在前，然后是最近 star 的），同样强度的命中不该被打乱。这一点和 GitHub 不同——GitHub 同分时按 star 数排，那是浏览场景的偏好；对启动器来说"最近 star 的更可能是我在找的"更实用。

### camelCase 切词的两种边界

`CLIProxyAPI` 这类名字需要两条规则才能切对：

1. 非大写后面跟大写 → 起新词：`OpenMission` → `Open` / `Mission`
2. 大写串后面跟小写 → 最后那个大写属于新词而非缩写：`CLIProxy` → `CLI` / `Proxy`

只有第 1 条会把 `CLIProxyAPI` 切成 `CLIP` / `roxy` / `API`。

## 为什么要预建索引

规则本身没问题，性能是问题。在 2233 个仓库的真实缓存上实测，每次查询都重新分词需要 **45–60ms**——快捷栏是逐字符触发的，这个延迟直接可感。

试过让分词按需进行（先做便宜的整名前缀检查，失败才切词），几乎没有改善：一次典型查询只有几条命中，剩下 2000 多条本来就要把所有字段都检查一遍才能排除。

所以改成 `RepositorySearchIndex`：构造时把每个仓库的 name / topics / description 一次性切成词数组存好，查询时只做字符串比较。

| | 每次查询 |
|---|---|
| 每次重新分词 | 45–60 ms |
| 预建索引 | 0.7–3.2 ms（中文子串查询 ~12 ms） |

索引构建本身约 46 ms，发生在**呼出面板时**（`preparePresentation` 顺带把索引建好，所以面板打开后的第一次按键就已经是热的），并且放在 `Task.detached` 里，不占主线程。

索引在两种情况下失效重建：任一仓库集合刷新完成（已有的 `repositoriesChangeIdentifier` 订阅），以及"包含私有仓库"开关变化（在取用索引时比对，不额外订阅）。

## 影响面

- `RepositorySearchCatalog` 只保留 `merged` 和分词工具函数；匹配和排序搬到新的 `RepositorySearchIndex`。
- `MainActionBarController` 从"每次搜索重新 merge 一遍列表"改成持有缓存索引，多了失效逻辑。
- 用户可见的行为变化：结果变少也变准，且开始排序；搜 owner 不再有结果。
- 缓存文件格式、刷新策略、私有仓库开关的语义都没有动。
