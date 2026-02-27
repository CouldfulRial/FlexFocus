# FlexFocus

macOS 可视化专注应用（MVP）。

## 已实现功能

- 中间主区：时钟 + 开始专注按钮。
- 点击开始后先输入任务，支持从历史任务快速选择。
- 开始后正计时；手动结束后记录本次专注。
- 结束专注后询问是否开始休息，休息倒计时为专注时长的 `1/5`，最短 `1` 分钟。
- 右侧专注历史：按日期分组、组内按时间倒序（最新在上）。
- 左侧统计栏：
	- 柱状图：按天/周/月/年聚合的专注时长
	- 云图：任务词频（频率越高字号越大）
	- 饼图：词汇对应专注时长占比

## 运行方式

```bash
swift build
swift run
```

建议在 Xcode 打开本目录后运行，以获得更好的 macOS UI 调试体验。

## 系统 Focus 模式接入

由于 macOS 对系统级 Focus 切换的公开 API 有限制，当前实现通过 `shortcuts` 命令触发快捷指令：

- `FlexFocus Start Focus`
- `FlexFocus Stop Focus`

请在系统“快捷指令”中创建上述两个快捷指令，并分别配置为：

- 开启你想使用的专注模式
- 关闭专注模式（或切换回默认）

若快捷指令不存在，App 仍可正常计时和记录，只是不会自动切换系统 Focus。

## 代码结构

- `Sources/FlexFocus/MainContentView.swift`：三栏主界面与流程串联
- `Sources/FlexFocus/ViewModels/FocusViewModel.swift`：专注/休息状态机与计时逻辑
- `Sources/FlexFocus/Services/SessionStore.swift`：本地 JSON 持久化
- `Sources/FlexFocus/Services/FocusModeService.swift`：Shortcuts 桥接
- `Sources/FlexFocus/Views/*`：UI 组件（计时区、历史区、统计区、任务输入）
- `Sources/FlexFocus/Support/*`：分组与统计聚合