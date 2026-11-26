# Orca 中文说明文档评审（本机只读核对）

## A. 事实核对

已读取指定的两份 HTML 本机文件，并与任务内联源码核对：`orca-tree-2f9c.html`、`orca-flow-8d41.html`。本机 CLI 只读核对包括 `orca --help`、`orca skills get orchestration`、`orca orchestration worker-start --help`、`task-create/task-list/task-update/run-create/run-show/dispatch-show/worker-show --help`、`orca bot list/chats`、`orca worktree list/ps --since 7d`、`orca repo list`、`orca bot item list`、`orca automations list`。样例文件的主要 HTML 内容与内联源码一致；报告只对这两份给定源码所表达的说法下结论。

1. **Worker“种类”不是 Agent 清单。** 树图写“这是 worker「分好几种」的真正含义”，旁列 `pi · claude · codex · cursor · antigravity · opencode · zcode …`。CLI help 说明 `--agent` 是“known TUI agent”，列表明确含 `muse`、`opencode2`，缺省不应由截图清单推断 worker 的种类；本机实际可选值以任务提供的九项为准，树图漏了 muse、opencode2。更准确说法是：Worker 是受监督的执行者/派发实例，Agent 是启动它的执行程序类型；还可用 `--terminal` 指定既有终端，并非只有这些 agent 类型。
2. **Task / Run / Dispatch / Worker 层级表述错误。** 树图写“Run 里挂着几个 Task，每个 Task 归一个 dispatch 的 worker”，把 Run 说成“一次协调上下文”，且把 Task/Run 放在 Worker 六样概念最后，读序不清。CLI 的 `run-create` help 称 Run 是“namespace and home inbox”，并明确 Run 本身“never schedules or places workers”；Task 有 pending/ready/dispatched/completed/failed/blocked 状态；worker-start 可创建/接续 Task 并产生 Dispatch，Dispatch 是一次派发记录，Worker 是执行该 Dispatch 的 agent（并非其上位 Task 的同义词）。建议顺序写：Run（协调命名空间/收件箱）→ Task（要完成的工作项）→ Dispatch（把 Task 派给执行者的一次派发）→ Worker/Agent（执行）；用“通常关联”而非“每个必然归属”表达，因 CLI 也支持无需显式 Run 的 worker-start 自动创建 Run。
3. **Terminal 与 Agent 不构成必然的一对一父子层级。** 树图把 Terminal 放在 Agent 前，并写“agent 跑在里面”。worker-start help 明说“Not every worker has a terminal”，并提示 `--terminal` 可复用已存在 terminal；故有些 Worker 没有 Terminal，Terminal 也不是 Worker 的类别。建议改为可选执行资源的并列关系；若展示，标“部分 Worker 由 terminal 承载”。
4. **Worktree 不是“worker 自己的目录+分支”必然属性。** 树图写“自己的目录 + 自己的分支”，卡片又称“worker 干活用的独立目录 + 独立分支”。CLI 支持 `--worktree current|selector|new-child|new-top-level`，也可用现有 terminal/worktree；因此“新工作区”是隔离工作的一种推荐，不是每个 worker 必然拥有。`orca worktree list` 实测工作区项有路径/分支/parentWorktreeId 等元数据；两个样例分别显示 `D:/night/orca/workspaces/frpwaf/frpwaf-gap-audit`、`D:/night/orca/workspaces/night-flow/wallet-subscription`，且 `under bot` 是归属信息，不等于目录/分支嵌套在 Bot 下。
5. **“一个分支一个目录”过度简化。** 源文标签“= 一个分支一个目录”适合描述 Git worktree 的常见形态，但不是 Orca 工作区的充分定义：还存在文件夹工作区；当前 repo 主工作树也作为工作区登记；worktree 路径可能在全局 workspaces 根下，不与 repo 根目录相邻。实测 `worktree list` 的 `night-flow` 主工作树在 `D:/night/gitea/night-flow`，`wallet-subscription` 则在 `D:/night/orca/workspaces/night-flow/wallet-subscription`。应区分 Repo、Git worktree、Folder workspace，并在图中单列 workspaceDir/根目录设置（此前评审此点正确，但应避免说“每个 worktree 都在根目录下”：主工作树可在 repo 原路径）。
6. **Item 不止“三档”。** 卡片原文“状态三档：In progress / Waiting / Needs you”；`orca bot item list --help` 明确开放项默认还包括 `Planned`，CLI 实测也有 #62 In progress。至少应写“常见处理状态”，并包括 Planned；不要把待办状态排除在台账状态之外。`In progress` 既可表示 bot/worker 正在处理，也可表示当前已接手；Waiting 指外部等待，Needs you 是等待 owner 决策，不应简单概括成只有三档流程。
7. **Automation 定位写得太宽。** 树图说“盯 PR、盯 CI、到点提醒都靠它”，流程表称“要等外部（CI / 别人评审 / 到点）→ automation 等待”。CLI 中 automation 确实是按计划或事件运行的等待/触发工具，但它不是每次等待的唯一手段，也不会自动替代 Item 记录责任；PR/CI 可用何种触发以 `trigger-options` 当前列出为准。本机 `orca automations list` 返回“No automations found”，所以树图“现在 0 个”此刻经核实为真，但它是瞬时数字，应注明核对时间。
8. **流转图把成功完成说成“worker_done 才醒来”，不完整。** 流程第 6 步和注释原文“收到 worker_done 才醒来”“worker 干完 / 卡住 / 要授权，Orca 自己把 bot 叫醒”互相不一致。CLI 区分 Worker/Task 结果，也有等待人工提示 `observation.agentWait`；worker-show help 明说等待人类回答的 worker 是“healthy, not failed”。失败、等待人工、派发未就绪、worker 能力不符都不是成功报告，需分别处理，不能把 worker 停在人工提示当作失败或宣称所有卡住都自动唤醒。
9. **派发范例不足以说明能力/失败重试。** 第 4 步给出 `worker-start --repo ... --worktree new-child ... --agent ... --item ...`，语法本身与 help 相容，但没说明需核对执行机/本机文件、工具权限、模型环境；`--on` 只选择 worker server，不保证它能访问另一台机器的文件。`--retry-of` 必须结合失败 Task 的 `--task`，且不会继承原 `--on/worktree/agent`，需重新指定；流程没有画失败重试/改派环节。
10. **决策文案过于绝对且责任划分失真。** flow 表“另一个 bot / 子聊天”理由写“职责分开，记忆不串”，但跨 bot 交接有 `handoff`（任务移交）、`question`（请教后由发起者收口）、`status`（只同步）三类；不是项目边界，也不是换 bot 就自动转移责任。Owner 已明确否定“一项目一个 bot”和“不建 Item 不开 worker”，不可保留为硬规则。

对先前评审的核对：它指出 Terminal 与 Agent 不一一对应、flow 只画成功路径、应加入 workspace 根目录，均有原文/CLI 依据；但“Task/Run 位置放反”不应仅靠图上挪位解决，根因是 Run、Task、Dispatch 的定义和关联写错，应改成顺序与关系说明。它关于 worker“缺设备权限会悄悄产出假报告”的断言，本任务可用的 CLI 证据不足，不能当作已核实事实；应改为一般性的访问能力前置检查及要求可验证证据。

## B. 结构与清晰度

### 树图

- 有结构性误导：顶层 `Orca → Bot / Repo / Folder` 看起来像严格的包含树；Bot、Repo、Folder 是不同实体/登记对象，不应暗示 Repo 属于 Bot 或 Folder 是 Bot 的子级。可保留树形视觉，但改成以“本机/服务器”为范围，下面分列“身份与对话”“项目与工作区”“调度与跟踪”三组。
- `Bot → Worker → Terminal → Agent → Worktree` 是错位串联；Task/Run 应先介绍，Worker/Agent/Terminal 是执行关系，Worktree 是可选执行场地。
- “工作区根目录”有价值，但必须呈现为一个全局位置/设置，并说明 repo 主目录可仍在原位置；不能将根目录画成 Repo 的父级，也不能说所有工作区都一定由其派生。
- 术语堆叠：`Run / Task / Dispatch / worker / agent / terminal / worktree / Item` 同时出现却不分“工作定义、派发记录、执行者、文件位置、跟踪台账”，对非技术读者负担过重。主图展示六个概念即可，Run/Task/Dispatch 放简短旁注。

### 七步流转图

- 第 1 步明确验收标准是优点；第 5 步写“提交 → 开 PR → 报告”却不应暗示每个任务都必须提交和开 PR。第 6 步“醒来后验收”没有验收清单/证据和失败后的回路。
- 缺少失败重试、worker 能力/权限不符时停止并改派、worker 等人工输入时转 Needs you/提问，以及验收失败时回到修复的分支。
- “一次最多约 4 个”只在表格写出，没有解释这是软建议/当前调度并发经验而非 CLI 固定限制。建议写“按上下文承载与风险控制并发，先从少量开始；超过团队设定上限时等任务回报后再补派”，具体数值应注明是本地经验并定期核对。
- “不许轮询、不许干等”“收到 worker_done 才醒来”易误解为无需检查状态；可改为“派发后不要用循环轮询；以 Orca 通知/worker 状态为准，并为外部等待建立 automation 与 Item”。
- 复审应是按风险选择，不是强制再开 reviewer；独立评审属于需要独立验证时的手段。

## C. 非绝对、可执行的替代方案

### bot 之间交接，而非“一项目一个 bot”

按责任是否转移选择消息类型：

- 整件工作交给另一个 bot，由接收方负责执行和答复：`orca orchestration send --to bot:<name> --type handoff --subject "..." --body "范围、现状、验收标准、限制"`。
- 只请教一个问题，自己仍负责收尾：`orca orchestration send --to bot:<name> --type question --subject "..."`。
- 只同步背景、不转移责任：使用 `--type status --subject ... --body ...`。
- 任务确实需要与对方 Home Chat 隔离时，用 `--chat new`；否则默认送到对方 Home Chat。判断标准不是“项目归谁”，而是“接收方是否要接管交付、是否需要隔离对话”。交接文字应包含当前证据、已完成/未完成、下一步、验收标准及需要的本机/远端环境。

### Item 与 Worker 按持续性和成本选用，不作硬门槛

- Item：若事项跨回合仍需跟进（等待 CI/评审/答复、多阶段交付、需要 owner 决策），建议建 Item；一次性查答或当场完成的小事可直接回复。Item 适用于追踪责任/状态，不是启动 worker 的前提。可用 `orca bot item add --title "..." --done-means "..."`；做完用 `orca bot item done <n>`，被放弃则记录原因并 cancel。
- Worker：只有当隔离环境、较长执行、多项并行或独立评审的收益高于派发/验收开销时再开；小而清楚、能立即验证的操作可自己完成。派发前确认 `--agent` 是否可用、选定 server 是否有需要的文件/工具/权限、工作区是否合适。例：`orca orchestration worker-start --spec "..." --repo <项目> --worktree new-child --name <短名> --agent pi --item <n>`。只有能拆成互不依赖的工作时并行；失败后检查 Task/Dispatch 状态与原因，再决定修正 spec 重试、换 agent/server、自己接手或关闭，不盲目重启。
- 完成并验收后再清理不再使用的工作区；若 worker 尚未结束、PR/复审仍需该目录或正在等待输入，不应提前清理。保留“写完就清工作区”的原则，但写清“完成且不再需要时清”。

## D. 可直接替换的中文修订文案

### 建议替换全景图的概念说明

> **Orca 里有几类不同的东西**
>
> - **Bot**：长期使用的身份和对话入口；多个 bot 可以通过交接协作，不按项目划死边界。
> - **Chat**：一次对话上下文。每个 bot 有 Home Chat，也可以有子聊天；另开子聊天用于隔离不同话题，不代表新建了 bot 或工作区。
> - **Run / Task / Dispatch**：Run 是协调工作的命名空间和收件箱；Task 描述要完成的工作；Dispatch 记录一次把工作交给执行者的派发。它们不是 Item 的别名。
> - **Worker / Agent**：Worker 是受监督的执行实例；Agent 是启动它所用的执行程序类型。并非每个 worker 都有 terminal，也不要求每个 worker 都新建 worktree。
> - **Worktree / Folder workspace**：工作文件位置。Git worktree 通常对应独立目录与分支；文件夹工作区则不一定是 Git 仓库。新建工作区可能位于配置的 workspace 根目录，repo 主工作树仍可能在 repo 原路径。Worker 可使用新建或现有工作区。
> - **Item**：跨回合跟踪交付、责任和待决事项的台账。包括 Planned、In progress、Waiting、Needs you 等状态；按需要使用，不是每项工作的强制前置条件。
> - **Automation**：按时间或受支持事件触发一次后续处理/提醒的机制；具体触发能力以 `orca automations trigger-options` 为准。它补充 Item，不取代责任人和状态记录。
>
> ### 建议替换“正常流转”
>
> 1. 说清需求、完成标准和限制；若依赖本机文件、网络、CLI 或特定权限，明确写出。
> 2. 选择执行方式：小而可即时验证的事项可由当前 bot 处理；工作量、风险、隔离或并行收益足以抵消派发开销时再开 worker。Item 和 worker 都是按需工具，不是硬性门槛。
> 3. 派发前确认目标执行机/agent 能访问所需材料与工具，选择现有工作区或新工作区，并把 spec 写成范围、不可触碰项、验收证据和交付格式。
> 4. 如需委派给另一个 bot，明确使用 handoff（交出责任）、question（请教但自己收尾）或 status（只同步）；不要用“项目归属”替代交接约定。
> 5. 只有互不依赖的任务并行派发，并发量按当前容量控制；依赖任务按顺序执行。新工作区通常由一名写手修改；需多人协作时先明确目录/文件所有权。
> 6. 派发后不循环轮询；依据 Orca 通知和状态跟进。Worker 完成时检查实际变更、测试/验收证据和剩余事项；需要时安排独立复审。worker 等待人工输入时回答或升级给 owner，不要误判为失败。
> 7. 验收通过后更新 Item、向 owner 汇报；失败或能力不符则记录原因，修正 spec 后有针对性重试、改派到合适的 bot/server，或自己接手。PR/外部评审/CI 等后续等待可按支持的触发创建 automation，并保留 Item 追踪。
> 8. 工作完成、验收通过且不再需要该目录后，清理工作区；不要在仍有修复、复审或外部依赖时提前清理。

### 最值得补进全景图的 5 点

1. Run → Task → Dispatch → Worker 的关系，并注明 Run 不负责调度/放置 worker。
2. Worker、Agent、Terminal 是不同概念；Worker 可能没有 terminal，Agent 类型由目标 server 可用项决定。
3. Repo 原路径、workspace 根目录、新 worktree 路径三者分开标示；Folder workspace 另列。
4. 交接类型 handoff / question / status 对应“移交责任 / 保留责任请教 / 仅同步”。
5. 成功、失败重试、人工等待/能力不符、验收和清理分支；并把 Item/Automation 标成辅助跟踪手段而非层级节点。

## 结论

错误/需修订项共 **10 条**（A 节编号 1–10；包含事实不准、关系层级误导及流程缺支）。本机确认 Bot 5 个、Repo 9 个、Automation 0 个；样例 worktree 路径和 jarvis 子聊天实例与任务背景相符。此前评审的核心结构警示部分成立，但其 Task/Run 结论应改成上述四层关系，设备权限事故的具体推断未核实。全景树状图不宜继续画成严格的包含树，应改为按“身份/协调/执行/工作区/跟踪”分组的关系图。
