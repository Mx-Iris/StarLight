# 窗口尺寸与定位：AppKit 与 SwiftUI 的三层机制

## 这篇讲什么

macOS 上一个窗口的大小和位置由谁决定，答案不止一个。AppKit 有三条独立通路能改窗口
frame，`NSHostingView` 又在上面叠了四套把 SwiftUI 尺寸交给 AppKit 的机制，SwiftUI Scene
再在最上面加一层自己的摆放逻辑。这些机制的**触发时机不同、锚定规则也不同**，混用时会互相
打架，而且从 API 签名和官方文档上完全看不出来。

这篇记录的是把这三层拆开逐条验证的结果。结论基于 macOS 26.6 的 AppKit 与 SwiftUI 7.6.1
反编译，附录列了每条结论对应的符号与地址，便于日后在新系统版本上复核。

**为什么值得单独成篇**：这一整块的失败模式全都是"看起来该生效但没生效"——代码没报错、约束
没冲突、日志没输出，窗口就是摆错了位置。而正确做法（把窗口锚点设成中心）从任何文档里都推不
出来，必须知道 AppKit 默认锚定左上角这个事实。

## 一句话结论

**窗口的最终尺寸由 Auto Layout 决定，而 Auto Layout 改变窗口大小时，默认锚定窗口的左上角。**
在尺寸定下来之前做的任何居中，都会变成"把左上角摆到屏幕中心"。

## 起因

`SettingsWindowController` 在 `windowDidLoad()` 里调 `centerInScreen()`，窗口却出现在屏幕中心
的右下方。把居中挪到 `showWindow` 之前也没用，现象变成窗口左上角精确地停在屏幕中心。

原因链条：

1. `XiblessWindowController` 默认用 `contentRect: .zero` 建窗口，所以窗口一开始是 0×0
2. `SettingsCoordinator.init` 里访问 `windowController.window` 触发 `loadWindow()` →
   `windowDidLoad()`。此刻窗口还是 0×0，`centerInScreen()` 把这个零尺寸窗口摆到了屏幕正中
3. 赋 `contentViewController` 并不会撑开窗口（见后文「通路 A2」）
4. 窗口真正变成 500×N 是在第一次 update-constraints + layout 之后，由 Auto Layout 完成
5. Auto Layout 改窗口大小时锚定左上角，于是左上角留在屏幕中心，窗口朝右下长出去

## 第一层：AppKit 怎么决定窗口 frame

### 三条通路

**通路 A —— `-[NSWindow setContentSize:]`**

代码直调，或由 AppKit 内部调用。锚点分三种情况：

| 当前 content rect | 锚点 |
|---|---|
| 空矩形（宽或高为 0） | **左下角**（保持 `frame.origin` 不变） |
| 非空，且窗口是 sheet | 顶边固定、水平居中 |
| 非空，其它情况 | 按 `anchorAttribute`，默认**左上角** |

空矩形那条特判存在的原因是：非空分支要拿 `frame.size` 当除数来换算锚点比例，零尺寸会除零。
副作用是**同一个零尺寸窗口在两条通路上的落点不一样**，这让问题特别难定位。

**通路 A2 —— 赋 `contentViewController`**

`-[NSWindow _contentViewControllerChanged]` 读的是 `contentViewController.view.frame`，
**不是 `fittingSize`**：

```objc
let targetFrame = self.frameRectForContentRect(vc.view.frame)
if !NSEqualSizes(self.frame.size, targetFrame.size) {
    self.setContentSize(self.contentRectForFrameRect(targetFrame).size)
}
self.setContentView(vc.view)
```

`NSHostingView` 刚 `loadView` 出来时 frame 是零，所以这一步只会把窗口"重置"成零宽加一个标题
栏高度，**不会**把它撑开。如果之前手动 `setFrame` 过，这一步会把它抹掉。

**通路 B —— 约束引擎**

窗口参与 Auto Layout，引擎求解出新尺寸后由
`-[NSWindow _changeWindowFrameFromConstraintsIfNecessary]` 落地：

```objc
新 origin = 旧 origin + (_layout_anchorPoint - _layout_anchorPointInEngine)
```

也就是**让锚点在屏幕上的绝对位置保持不变**，窗口围绕锚点生长。

**通路 C —— 用户拖拽边框**

live resize，由拖的是哪条边决定，不看 `anchorAttribute`。

### 锚点：默认就是左上角

通路 A（非空）和通路 B 都取 `anchorAttribute`，它来自 `_NSWindowDefaultAnchorInfo`：

```objc
horizontalAttribute = NSLayoutAttributeLeft   // 1
verticalAttribute   = NSLayoutAttributeTop    // 3
```

对照 sheet 的默认值 `_NSSheetDefaultAnchorInfo` 是 `centerX`(9) + `top`(3) —— 这正是 sheet
长高时"水平居中、顶边贴住"的来源。**同一套机制，Apple 自己就在用**。

改锚点用公开 API `NSWindow.setAnchorAttribute(_:for:)`（macOS 10.9+）。

### `layoutIfNeeded()` 天然差一拍

`-[NSWindow layoutIfNeeded]` 的内部顺序是：

1. `updateConstraintsIfNeeded`
2. 跑约束引擎 → `_changeWindowFrameFromConstraintsIfNecessary`（**这里改窗口 frame**）
3. `_layoutViewTree`（**SwiftUI 在这里才算出理想尺寸**）
4. 发 `NSWindowDidLayoutNotification`

SwiftUI 在第 3 步才写出新的理想尺寸，而窗口 frame 在第 2 步就已经定了。**调一次
`layoutIfNeeded()` 拿到的永远是上一轮的尺寸。**

## 第二层：NSHostingView 把 SwiftUI 尺寸交给 AppKit 的四种方式

### `sizingOptions` 四个选项走四套完全不同的机制

`NSHostingView.SizeConstraints.update(from:)` 里，四个选项互不复用：

| 选项 | 机制 | 优先级 |
|---|---|---|
| `.minSize` | 在 hosting view 上装 `widthAnchor >= / heightAnchor >=` | ≈999.9 |
| `.maxSize` | 装 `widthAnchor <= / heightAnchor <=` | ≈999.9 |
| `.intrinsicContentSize` | 调 `invalidateIntrinsicContentSize()` | 走固有尺寸 |
| `.preferredContentSize` | **不装任何约束** | 见下 |

`.preferredContentSize` 只做一件事：让 `NSHostingController.preferredContentSize` 这个 getter
返回 SwiftUI 当前的理想尺寸。真正装约束的是 **AppKit**：

```objc
// -[NSViewController updateViewConstraints]
CGSize preferred = self.preferredContentSize;
if (preferred.width > 0 && preferred.height > 0) {
    _NSReplaceDimensionConstraint(view, NSLayoutAttributeWidth,  preferred.width);
    _NSReplaceDimensionConstraint(view, NSLayoutAttributeHeight, preferred.height);
}
```

装出来的约束：

- identifier 是 `"NSViewController.preferredContentSize.width"` / `".height"`，调试时可以按名字找
- 关系是 `.equal`
- **优先级只有 500**

500 低于 `.defaultHigh`(750)，远低于 SwiftUI 自己那条 ≈999.9。三者冲突时，
`.preferredContentSize` 是最先被牺牲的那个。

另外注意 `preferred.width > 0 && preferred.height > 0` 这个前置条件：SwiftUI 理想尺寸有一维
是 0 时，约束根本不会装。

还有一个不对称：`SizeConstraints` 里只有 `idealHeightConstraint`，**没有 idealWidth**。理想宽
度只能走 `.intrinsicContentSize`。

### 副作用：会覆写窗口的 `contentMinSize` / `contentMaxSize`

`NSHostingView.updateWindowContentSizeExtremaIfNecessary()` 在每次 `updateConstraints` 时跑，
触发条件只有一个 —— hosting view 恰好是 `window.contentView`：

```swift
guard !isUpdatingWindowContentSizeExtrema else { return }
guard let window, window.contentView === self, !window.inLiveResize else { return }

window.contentMinSize = minSizeRoundedRespectingSizingOptions()
window.contentMaxSize = max(maxSizeRounded..., minSizeRounded...)
// 若理想尺寸或 min/max 变了，把 content size clamp 回区间（又一次 setContentSize:）
```

关键在那两个 `...RespectingSizingOptions()` 在选项没开时返回的是**兜底值，不是"不动"**：

- 没开 `.minSize` → 返回 `(0, 0)`
- 没开 `.maxSize` → 返回 `(1.797e308, 1.797e308)`

**所以你自己设的 `window.contentMinSize` 会被悄悄抹成零。** 想给窗口设下限，要么给
`sizingOptions` 加 `.minSize` 让 SwiftUI 去设，要么在 SwiftUI 侧写 `.frame(minWidth:minHeight:)`。

## 第三层：SwiftUI Scene 自己管窗口时

### 分水岭是一个弱引用

```swift
// NSHostingView
weak var delegate: NSHostingViewDelegate?
```

`NSHostingViewDelegate` 有 13 个回调，其中五个与尺寸有关（`hostingViewDidUpdateConstraints`、
`didUpdateIdealHeight`、`didUpdateMinSize:maxSize:`、`didUpdateWindowMinSize:maxSize:`、
`didChangeWindowLayoutComputer`）。

**这个 delegate 只有 SwiftUI 自己的 `AppKitWindowController`（`NSWindowController` 子类）会设。**
在 AppKit 里手动 `NSHostingController(rootView:)` 时它恒为 nil，五个回调全部空转 —— 每个调用
点都是"取弱引用，为 nil 就整段跳过"。

### Scene 怎么摆窗口：先定尺寸，再显式算原点

`AppKitWindowController.sizeAndPlaceWindow()`，三条分支：

- **层叠**：`sourceWindowForCascading` 找到参照窗口 → `setFrame(source.cascadingReferenceFrame)`
- **经典**：`sizeThatFits(defaultSize ?? WindowSizeConstants.defaultProposedSize)` →
  `setContentSize` → `AppWindowsController.placeWindow(_:info:)`
- **WindowLayout（macOS 26）**：多一层 `WindowLayoutEngine` 求解，仍然是 `setContentSize` →
  `setFrameOrigin` 两步

三条都以「`isRestorable && shouldUseAutosaveName` 时挂 `setFrameAutosaveName`」收尾。

居中的实现在 `AppWindowsController.placeWindow(_:info:)`：

```swift
let visible  = NSScreen.main.visibleFrame
let position = item.defaultPosition ?? info.defaultPositionFallback ?? .center

let flip = CGAffineTransformMakeScale(1, -1)   // UnitPoint 是 top-left 语义
let containerPoint = position.in(visible.applying(flip))
let windowPoint    = position.in(window.frame.applying(flip))
window.setFrameOrigin(window.frame.origin + (containerPoint - windowPoint).applying(flip))
```

一句话：**把窗口内的那个 UnitPoint 挪到屏幕 visibleFrame 内的同一个 UnitPoint 上**，默认
`.center`。全程 `setFrameOrigin`，跟 `anchorAttribute` 完全无关。

### `windowResizability` 的完整闭环

```
WindowResizability.Role
  └─ AppKitWindowController.adjustSizingOptionsIfNecessary
       .automatic      → sizingOptions = [.minSize]
       .contentSize    → [.minSize, .maxSize]
       .contentMinSize → [.minSize]
       .full           → []
       nil / 旧 SDK    → .standardBounds
  └─ SizeConstraints.update → 装约束 + 写 window.contentMinSize / contentMaxSize
  └─ WindowBehaviorBridge.updateResizability(window:)
       if contentMinSize == contentMaxSize → 摘掉 styleMask 的 .resizable
```

`.contentSize` 让 min 和 max 都等于理想尺寸，于是两者相等，于是 `.resizable` 被摘掉 ——
**"窗口不能拖" 不是直接设 styleMask，而是 min/max 撞在一起的副产物**。窗口处于全屏
（`styleMask & .fullScreen`）时强制保留 `.resizable`，否则退不出全屏。

### `windowResizeAnchor` 在 AppKit 宿主里无效

`View.windowResizeAnchor(_:)` 是 macOS 26 的公开 API，文档写着 "the anchor point is respected
in all cases"。实际情况要打折扣：

**SwiftUI 从不调用 `setAnchorAttribute:forOrientation:`，也从不设 `_layout_setPrimitiveAnchorInfo:`。**
这两个 selector 的全部调用点都在 AppKit 内部（`NSSplitViewController`、`NSAlert`、
`NSSavePanel`、`NSPopoverFrame`）。

`windowResizeAnchor` 存在 `NSHostingView.windowResizeAnchor`，经 `WindowResizeAnchorPreferenceKey`
传递、在 `preferencesDidChange()` 里写入，只有 SwiftUI 自己驱动窗口 resize 时才会读
（`WindowSizeBridge` / `updateAnimatedWindowSize`）。

**推论**：在 AppKit 宿主里，窗口 resize 是 AppKit 约束引擎做的，引擎只看
`NSWindow.anchorAttribute`。`.windowResizeAnchor(.center)` 那条 modifier 白写。

## 完整路线清单

所有能改变 `NSWindow` frame 的入口：

| # | 入口 | 阵营 | 定位规则 | 时机 |
|---|---|---|---|---|
| 1 | 手动 `setFrame` / `setContentSize` | 两者 | 见「通路 A」 | 随时 |
| 2 | `_contentViewControllerChanged` | 两者 | 读 `vc.view.frame` → `setContentSize:` | 赋 `contentViewController` |
| 3 | `preferredContentSize` → `updateViewConstraints` → 引擎 | 两者 | `anchorAttribute`，约束优先级 500 | 每次 update-constraints |
| 4 | SwiftUI min/max 约束 → 引擎 | 两者 | 同上，优先级 ≈999.9 | 同上 |
| 5 | `updateWindowContentSizeExtremaIfNecessary` 的 clamp | 两者 | `setContentSize:` | 每次 `updateConstraints`，非 live resize |
| 6 | 用户拖边框 | 两者 | 拖哪边算哪边 | live resize |
| 7 | `sizeAndPlaceWindow()` | 仅 Scene | 两步显式 | 窗口首次显示 |
| 8 | `placeWindow(_:info:)` | 仅 Scene | UnitPoint 对齐，默认 `.center` | 被 7 调用 |
| 9 | `cascadingReferenceFrame` | 仅 Scene | 参照窗口层叠 | 需要初始摆放时 |
| 10 | `WindowLayoutEngine` | 仅 Scene（26+） | 引擎求解 + 仿射变换 | 被 7 调用 |
| 11 | `WindowSizeBridge` / `updateAnimatedWindowSize` | 仅 Scene | `windowResizeAnchor` | 内容驱动的动画 resize |
| 12 | `setFrameAutosaveName` 恢复 | 仅 Scene 自动挂 | 上次保存的 frame | 窗口加载 |
| 13 | `windowWillUseStandardFrame(_:defaultFrame:)` | 仅 Scene | zoom 目标 | 点绿灯 |

1–6 两个阵营共有，7–13 是 Scene 独有。**AppKit 宿主只有 1–6，是一套完全被动的机制**：没有
初始摆放、没有默认位置、没有 autosave、没有 resizability，只有约束引擎按左上角锚点被动跟随。

### 两条路的对照

| | AppKit 宿主（StarLight） | SwiftUI Scene |
|---|---|---|
| `NSHostingView.delegate` | nil，回调全空转 | `AppKitWindowController` |
| 初始尺寸 / 位置 | 无人管 | `defaultSize` / `defaultPosition`（默认居中） |
| 内容变大时 | 约束引擎被动跟随，锚左上 | `windowResizeAnchor`，默认 topLeading |
| `.windowResizeAnchor()` | **无效** | 有效 |
| `setAnchorAttribute()` | **唯一手段** | 用不上（显式设 origin，绕过锚点） |
| `.windowResizability()` | 无效 | 有效 |
| `sizingOptions` | init 设死 | 按 resizability 运行时重算 |
| `contentMinSize` / `MaxSize` | 被覆写，无人兜底 | 被覆写，但 delegate 补全屏那一对 |
| 位置持久化 | 无 | `setFrameAutosaveName` |

## 本项目的结论

StarLight 是 AppKit 宿主：coordinator 树驱动 `NSWindowController`，SwiftUI 只经
`XiblessHostingController`（`NSHostingController` 子类，`sizingOptions = .preferredContentSize`）
接进来。所以上表左列全部适用 —— Scene 那一整套一个都用不上。

**Settings 窗口的正确做法是把窗口锚点设成中心，让 AppKit 自己维持居中：**

```swift
override func windowDidLoad() {
    super.windowDidLoad()

    // The window is created with a zero content rect and only reaches its real size once
    // SwiftUI's preferredContentSize turns into constraints. Constraint-driven resizes keep
    // the window's anchor point fixed, and that anchor defaults to the top-left corner, so
    // centering here would pin the top-left corner to the screen center. Anchoring both axes
    // to the center keeps the window centered as it grows.
    contentWindow.setAnchorAttribute(.centerX, for: .horizontal)
    contentWindow.setAnchorAttribute(.centerY, for: .vertical)
    contentWindow.box.centerInScreen()

    contentWindow.toolbar = NSToolbar()
    contentWindow.title = "Settings"
}
```

这个组合是**精确**居中，不是近似：零尺寸窗口的 frame 是 `(x, y, 0, 标题栏高)`，
`centerInScreen()` 把这个 frame 摆正中等价于把窗口中心点放在屏幕中心；之后以中心为锚点扩展，
中心点不动，最终窗口正好居中。

需要知道的两个副作用：

- 设了 `.centerY` 之后，Settings 里 "Sign In Again" 提示行出现/消失导致高度变化时，窗口会朝
  上下两端同时展开，而不是保持顶边。对一个每次打开都居中的窗口这更自然，但确实是可见的行为
  变化。
- 用户手动拖拽 resize 不受影响 —— 那条路径不经过约束引擎。

**为什么不用其它写法**：

- 在 `showWindow` 里居中 —— 那时窗口尺寸还没定（见「差一拍」一节）
- 调两次 `layoutIfNeeded()` —— 依赖内部执行顺序，脆
- `.windowResizeAnchor(.center)` —— AppKit 宿主里无效
- 硬编码 `setFrame(500×300)` 再居中 —— 会被通路 2 抹掉，且高度一旦变化就失准

另外两点与本项目相关：

- 想给 Settings 窗口设最小尺寸，别设 `window.contentMinSize`（会被抹成零），改用
  `sizingOptions` 加 `.minSize` 或在 SwiftUI 侧写 `.frame(minWidth:minHeight:)`
- `SettingsView` 的 `.frame(width: 500)` 经 `.preferredContentSize` 装出来的是优先级 500 的等
  宽约束。目前没有竞争者，但一旦窗口有了 min/max 约束（优先级 ≈999.9），这条 500 会先被牺牲
- `LoginWindowController` 的偏移小到看不出来：它用 `contentRect: 550×300` 建窗口，初始就有真实
  尺寸，SwiftUI 撑开前后差别不大。它原先用的 `positionCenter()` 只取 `visibleFrame.size` 而不加
  `origin`，多屏或 Dock 在侧边时会偏，已一并换成 `centerInScreen()`。**没有**给它设中心锚点 ——
  它初始尺寸接近最终尺寸，锚点带来的差异看不出来，保持改动最小

## 随 SDK 变化的行为

这类开关最坑 —— 换个 SDK 重编，同一份代码行为就变：

| 检查 | 影响 |
|---|---|
| `Semantics.v6`（`NSHostingView.viewDidMoveToWindow`） | 旧 SDK 在 `viewDidMoveToWindow` 就更新窗口 min/max；新 SDK 推迟到 `updateConstraints` |
| `Semantics_v4`（`adjustSizingOptionsIfNecessary`） | 旧 SDK 一律 `.standardBounds`，忽略 `windowResizability` |
| `NSWindowControllerSupports10_10Features` | 关掉后 `NSWindowController.contentViewController` 不再转发给 window |

## 附录：验证方法与符号地址

结论基于 macOS 26.6 的 dyld shared cache（AppKit + SwiftUI 7.6.1 + SwiftUICore，arm64e）反编
译。复核时按 CLAUDE.md 的约定用 `idalib` MCP 打开 shared cache，按下表定位。地址是 26.6 的，
换系统版本后会变，用符号名查即可。

### AppKit

| 符号 | 地址 | 用途 |
|---|---|---|
| `-[NSWindow setContentSize:]` | `0x184BEF9A4` | 通路 A，含空矩形特判 |
| `-[NSWindow _adjustedOriginAroundAnchorPointForSize:fromFrame:]` | `0x1859FA508` | 锚点换算公式 |
| `-[NSWindow _contentViewControllerChanged]` | `0x184BB78A4` | 通路 A2 |
| `-[NSWindow _changeWindowFrameFromConstraintsIfNecessary]` | `0x1859FA378` | 通路 B |
| `-[NSWindow _layout_anchorPoint]` | `0x1859F9CB4` | 锚点求值 |
| `_NSWindowDefaultAnchorInfo_block_invoke` | `0x184BAB47C` | 默认锚点 = left + top |
| `_NSSheetDefaultAnchorInfo_block_invoke` | `0x1859FAFE0` | sheet 锚点 = centerX + top |
| `-[NSWindow layoutIfNeeded]` | `0x1859FAA80` | 引擎与视图树的先后顺序 |
| `-[NSViewController updateViewConstraints]` | `0x184A78100` | preferredContentSize → 约束 |
| `_NSReplaceDimensionConstraint` | `0x1852A6490` | 约束 identifier 与优先级 500 |

### SwiftUI

| 符号 | 地址 | 用途 |
|---|---|---|
| `NSHostingController.preferredContentSize.getter` | `0x1B5AB70C4` | 返回 SwiftUI idealSize |
| `NSHostingView.SizeConstraints.update(from:)` | `0x1B61C6D48` | sizingOptions 四套机制 |
| `NSHostingView.updateWindowContentSizeExtremaIfNecessary()` | `0x1B61B6720` | 覆写窗口 min/max |
| `NSHostingView.minSizeRoundedRespectingSizingOptions()` | `0x1B61B6360` | 兜底 `(0,0)` |
| `NSHostingView.maxSizeRoundedRespectingSizingOptions()` | `0x1B61B63F8` | 兜底 `1.797e308` |
| `NSHostingView.invalidateSizeConstraintsIfNecessary()` | `0x1B61B73EC` | sizingOptions 位定义 |
| `NSHostingView.viewDidMoveToWindow()` | `0x1B61CB428` | `Semantics.v6` 分支 |
| `AppKitWindowController.sizeAndPlaceWindow()` | `0x1B6311460` | Scene 摆放主流程 |
| `AppWindowsController.placeWindow(_:info:)` | `0x1B632C394` | UnitPoint 居中算法 |
| `AppKitWindowController.adjustSizingOptionsIfNecessary(window:)` | `0x1B63131E0` | resizability → sizingOptions |
| `WindowBehaviorBridge.updateResizability(window:)` | `0x1B5E82E74` | min==max → 摘 `.resizable` |
| `AppKitWindowController.hostingView(_:didUpdateWindowMinSize:maxSize:)` | `0x1B6315420` | delegate 只补全屏尺寸 |

### `sizingOptions` 位定义

从 `SizeConstraints.update(from:)` 与 `NSHostingController.preferredContentSize.getter` 反推：

| 位 | 含义 |
|---|---|
| `0x01` | `.minSize` |
| `0x02` | `.intrinsicContentSize` |
| `0x04` | `.maxSize` |
| `0x08` / `0x20` | 控制 `idealHeightConstraint` 与 hugging 变体 |
| `0x10` | `.preferredContentSize` |

`NSHostingSizeBridgingOptions` 与 `NSHostingSizingOptions` 共用同一个 ivar（偏移 `0x1020`），
`sizeBridgingOptions` 的 getter 直接返回 `sizingOptions` 的 raw value。

### 相关的可重用 skill

同一份机制知识整理成了 agent skill `appkit-swiftui-window-sizing`（英文，位于全局 skills 目录），
覆盖症状速查、决策指南与本篇的核心结论，供其它项目复用。
