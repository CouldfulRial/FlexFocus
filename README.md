# FlexFocus

macOS 可视化专注应用（MVP）。

## 已实现功能

- 中间主区：时钟 + 开始专注按钮。
- 点击开始后先输入任务，支持从历史任务快速选择。
- 开始后正计时；手动结束后记录本次专注。
- 结束专注后询问是否开始休息，休息倒计时为专注时长的 `1/5`，最短 `1` 分钟。
- 专注计时为红色，休息计时为绿色。
- 右侧专注历史：按日期分组、组内按时间倒序（最新在上）。
- 左侧统计栏：
	- 柱状图（标题：`专注时长`）：按天/周/月/年聚合（interval 分别为 2 小时 / 天 / 3 天 / 月），Y 轴带时长单位
	- 词云：固定白底画布、词频映射字号、随机布局、避免重叠、少量竖排补空隙
	- 饼图（标题：`专注占比`）：固定画布显示，仅显示占比 > 10% 的百分比标注
- 设置窗口（`⌘,`）：
	- 专注开始时是否开启 DND
	- 专注结束时是否关闭 DND
	- 是否发送休息结束通知
	- 清除所有历史数据

## 运行方式

```bash
swift build
swift run
```

建议在 Xcode 打开本目录后运行，以获得更好的 macOS UI 调试体验。

> 注意：`swift run` 不是 `.app` bundle 运行环境，因此系统通知行为受限。若要完整验证通知与系统集成，建议使用 Xcode 运行或打包成 `.app`。

## 打包成 .app

项目已提供打包脚本：

```bash
chmod +x scripts/package_app.sh
./scripts/package_app.sh
```

输出路径：`dist/FlexFocus.app`

## 系统 Focus 模式接入

由于 macOS 对系统级 Focus 切换的公开 API 有限制，当前实现通过 `shortcuts` 命令触发快捷指令：

- `FlexFocus Start Focus`
- `FlexFocus Stop Focus`

请在系统“快捷指令”中创建上述两个快捷指令，并分别配置为：

- 开启你想使用的专注模式
- 关闭专注模式（或切换回默认）

若快捷指令不存在，App 仍可正常计时和记录，只是不会自动切换系统 Focus。

## 通知说明

- App 启动时（开启通知开关时）会请求系统通知权限。
- 休息倒计时结束后会发送本机通知提醒。
- 跨设备推送当前未接入（需 APNs / iCloud / 后端同步能力）。

## 代码结构

- `Sources/FlexFocus/MainContentView.swift`：三栏主界面与流程串联
- `Sources/FlexFocus/ViewModels/FocusViewModel.swift`：专注/休息状态机与计时逻辑
- `Sources/FlexFocus/Services/SessionStore.swift`：本地 JSON 持久化
- `Sources/FlexFocus/Services/FocusModeService.swift`：Shortcuts 桥接
- `Sources/FlexFocus/Views/*`：UI 组件（计时区、历史区、统计区、任务输入）
- `Sources/FlexFocus/Support/*`：分组与统计聚合