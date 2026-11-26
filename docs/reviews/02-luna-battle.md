# Orca 文档评审口径复核

## 争点一：未读原文仍产出内容

**立场：改口（对“行为事实”）；维持对“仅凭不能引用就证明未读”的保留。**

**理由：** 我读取了两份相关 Dispatch 的记录和第一份的 transcript。`worker-read --dispatch ctx_8a2f08a6e438 --source transcript` 明确包含 worker 自述：“I'm running in the cloud with no device access”，又说“can't access the HTML files”，随后表示会基于已粘贴内容起草 C/D；因此“worker 自述无法访问原文后仍继续交付内容”是有直接 transcript 证据的行为事实。Dispatch JSON 同时明确 `workspace:"folder:49c56bbf-7b9d-469d-a3b7-a2f22dfbbd64"`，与协调者指出的本机 bot home 放置相符；这使“因为放置在云端所以读不到”成为错误的原因解释，而非事实。第二个 Dispatch JSON 给出 `lastError:"Terminal closed by operator request"`、`attention:["failure","interruption"]`，支持它是操作者请求关闭导致的中断，不支持把它归因于设备能力不足。

“要求引用只有读过原文才知道的细节”是有用的验收判据，但单独的“引不出来”只能说明未提供可验证证据，不能逻辑上证明没有读过；本例更强的可核实证据是 transcript 的明确自述与它随后声明要基于粘贴材料继续写。报告里可描述本例行为，不应泛化成所有未引用的 worker 都没读原文。

**建议的一句话措辞：**“本例中，worker 的 transcript 明确自述无法访问本机 HTML，却仍表示将依据粘贴内容继续写 C/D；Dispatch 实际指向本机 bot-home folder，因此问题是 worker 自我误判能力后仍继续交付，而非派发到了云端。”

## 争点二：Worker 类别与承载形态

**(a) 立场：改口——承载形态可以作为一种有用的 worker 分类维度。** Orca 的概念不应只按 Agent 类型区分；“聊天/结构化承载”与“交互式 terminal 承载”是不同的操作体验与故障处置面。

**理由与引用：** `orca skills get orchestration --full` 写有“a worker may be a chat with none”；CLI `worker-show --help` 写有“Not every worker has a terminal”；同一 guide 又说“Drive every worker the same way whichever way it was started”，并提示统一通过 orchestration verbs 与 Dispatch handle 操作。因此“承载形态是可区分的外观/运维特征”成立，但不应推成它们有不同的调度实体或生命周期模型。

**(b) 立场：改口一半——可以把关闭承载窗口后 Dispatch 失败归入“承载/进程生命周期导致的失败”，但本次数据不支持精确写成‘关闭聊天窗口必然失败’。** `ctx_9104beec7f88` 的 `worker-show --json` 确认 `state:"failed"`、`stage:"process_exited"`、`lastError:"Terminal closed by operator request"`；它证明该次 operator request 关闭了运行所依附的 terminal 资源并导致进程退出/Dispatch failed。`ctx_8a2f08a6e438` 也显示 `terminal:"structworker_cb65f94e-a80f-4247-b48a-fe2f2b03a32e"`、`terminalState:"released"`。所以 CLI 返回的 terminal 标识即使前缀为 `structworker_` 也存在；文档若写“没有终端”会与字段冲突。可以写“非交互/结构化聊天承载，不提供普通可交互 terminal 窗格”，但除非产品定义另有明确说明，不应等同于“没有任何 terminal 资源”。

**(c) 立场：改口。** 我原 A 节“worker 种类只是 Agent 类型”的结论不完整，应撤回。`worker-start --help` 将 `--agent <id>` 定义为“Launch a known TUI agent in the first terminal”；同一 help 另有 `--terminal <handle>`，并明确“Not every worker has a terminal”。这显示 Agent 是执行程序/启动方式，Terminal/聊天承载是另一条轴。`--agent` 当前可用列表还包括 `muse`、`opencode2`，所以原文 agent 列表仍需补全；但补全 agent 名单不能替代承载形态说明。

**建议的一句话措辞：**“Worker 可按执行程序（Agent）和承载形态（结构化聊天/普通 terminal 等）分别描述；Agent 决定由什么执行，承载形态决定如何查看、交互和处理进程退出，且不是每个 worker 都有普通可交互 terminal。”

## 争点三：错误条数

**立场：改口——Task/Run 定义错与图中顺序/位置不佳应合并算一个根因项，不应重复计为两条独立错误。**

**理由：** 原评审 A 节第 2 项已指出定义/关系不清，第 3 项单列“Task / Run 一行放最后”的读序问题；后者只是同一概念关系错误的表现/修订方式，不是独立事实错误。因此若用“错误条数”量化，应将两者合并成一个“Task/Run/Dispatch/Worker 关系与呈现错误”，并把原来的 10 条改成 9 个独立问题（若保留子点，需明确说明是问题项而非独立错误数）。

## 最终可直接写入文档的两句话

1. “本例中，worker 自述无法访问本机 HTML，随后仍表示要依据粘贴材料继续写 C/D；Dispatch 指向本机 bot-home folder，准确教训是 worker 自我误判能力后仍继续交付，不是派发到了云端。”
2. “Worker 应分别按执行程序（Agent）和承载形态（结构化聊天或普通 terminal）描述；不是每个 worker 都提供普通交互式 terminal，关闭其承载进程可能令 Dispatch 失败，具体表现应以该次 Dispatch 的状态与错误字段为准。”
