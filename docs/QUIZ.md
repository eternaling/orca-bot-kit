# 考 bot：Orca 地图 23 问

用法：随便挑几条问 bot，看它答得对不对。**答案在最后，先别看。**

题目都挑的是 bot 历史上真答错过的坑，不是常识题。

---

## 题

1. worker 有终端吗？
2. Run 会调度 worker、会挑机器吗？
3. Item 的状态是不是「Planned → In progress → Waiting → Needs you」一条线走下来？
4. `--on <server>` 是不是意味着 worker 能读到那台机器上的目录？
5. `--retry-of` 重试时，会沿用上次的机器、工作区、agent（或复用的 `--terminal`）吗？哪些参数必须重新给？
6. Git worktree 一定有自己的分支吗？
7. 怎么判断一个 worker 到底有没有真读文件？
8. 一个结构化 worker 的聊天窗口被关掉，那次派发会怎样？
9. bot 之间要交接活，有哪几种方式，分别什么意思？
10. 派完 worker 之后，bot 该守着还是干别的？

## 加分题（更难，考它会不会含糊）

11. `--agent` 那些选项（pi/claude/codex…）是什么东西的种类？worker 的「种类」又是什么？
12. 主路第 3 步是干嘛的？跳过它会有什么后果？

## 补考题（2026-11-26 新增）

13. `--worktree` 有几种取值？能不能在远程机器上用 `current`？
14. `worker-start` 里 `--item` 和 `--on` 能一起用吗？
15. `worker-show` 显示 `stopReason=lost`、liveness `unverifiable`，该重试还是该发信催它？

## 二轮补考（2026-11-26 清理轮新增，前置审计提过但一直没考到）

16. 目标是 `current` 或已有工作区，还能带 `--name / --repo / --base-branch / --display-name / --comment / --setup` 吗？
17. `worker-show` 打出来的 `state=stopped` 是 Task 的状态吗？Task 到底有哪六态？
18. 想把失败那次改好 spec，再用 `--retry-of` 重派，算重试吗？`--retry-of` 必须配哪个参数？
19. 一条 dispatch 记录里有 `structworker_…` 资源标识，能说明它有可交互终端吗？判据是什么？
20. `--environment local` 和 `--on <server>` 是一回事吗？

## 三轮补考（2026-11-26 对账 1.4.278 命令面时新增）

21. worker 卡住了，你想「先隔离住、但别动它的进程」，用 `worker-stop` 还是 `worker-abandon`？两者区别是什么？
22. `send --type` 一共几种？`worker_done` 必须带什么？哪两种类型不能发给群组？
23. 你只跑了 `worker-show --json`，看到 `waitingOnHuman=unknown`，能断定它不在等人吗？该怎么查？

---

## 答案

1. **不能简单说「没有」。** CLI 原话 `Not every worker has a terminal` = 没有**可交互的终端窗格**；结构化承载**常见**带 `structworker_…` 终端资源标识（但不是通则，别拿这个字段存在当证据）。说「没有终端」与字段矛盾。
   ⚠️ 常见错答：「不是每个都有终端，有些没有」——这句话本身对，但没区分「资源标识」和「可交互窗格」。

2. **不会。** `A Run is a namespace and home inbox. It never schedules or places workers.`
   ⚠️ 常见错答：把 Run 说成「一次协调上下文，里面挂着几个 Task 并负责调度」。

3. **不是。** Planned / In progress / Waiting / Needs you 是并列的开着状态，Waiting 和 Needs you 不互相派生，不需要按顺序走。

4. **不意味着。** `--on` 选的是 worker 所在的 Orca server；Run 和发起命令仍在当前 Orca server。它不保证 worker 能读到另一台机器上的目录。

5. **不会。** `--retry-of` 必须配原 `--task`，且不继承原来的位置：`--on` / `--worktree` / `--agent`（或 `--terminal`）**四组都要重述**。另注意：改了 spec 就是新建 Task，不算重试。

6. **不一定。** worktree 是独立工作目录，通常检出一个分支，也可处于 detached HEAD。

7. **看 transcript 原话**（`orca orchestration worker-read --source transcript`）。要求它引用只有读过才知道的细节是**降级判据**——引不出只说明没给证据，不能反推「肯定没读」。
   ⚠️ 常见错答：「引不出细节就是没读」——这是过度推断，曾经因此误判。

8. **那次 dispatch 直接 failed**，`lastError="Terminal closed by operator request"`，不是它自己在故障。

9. **三种**：`handoff` 连责任一起交出去；`question` 只请教、自己仍负责收尾；`status` 只同步背景、不转移责任。

10. **干别的。** 派完就结束回合，不轮询、不 sleep；Orca 在它完成 / 失败 / 等人类回答时叫醒 bot。

11. `pi/claude/codex/cursor/antigravity/muse/zcode/opencode/opencode2` 是 **Agent（执行程序）类型**，不是 worker 的种类。而且 CLI 原文是 `such as` 引出的**开放列举（非穷尽）**——`pi` 就不在那句名单里却实际在用，别把它当全部种类。worker 按两条轴看：**执行程序**和**承载形态**（结构化聊天 / 普通 terminal）。定模型与深度用 `--model provider/id` + `--effort off/minimal/low/medium/high/xhigh/max`。

12. **确认对方够得到料**：机器、文件、工具、agent 类型、模型。跳过它的后果是白跑一轮——本地已有实例：一个 worker 自称在云端、说没设备权限，**其实它就在本机 bot home（不是 Orca 放错机器）**，没读文件就写了报告；另外两个被关掉窗口直接 failed。

13. **四值：`current` / `selector` / `new-child` / `new-top-level`。远程不能用 `current`**，原文 `Remote current is invalid.`
    ⚠️ 常见错答：「就 current 和 new-child 两种」——漏了 `selector` 和 `new-top-level`。

14. **不能。** 原文 `It can't be combined with --on.` 想既挂 Item 台账又指定 `--on <server>`，得换个写法或者分两次。

15. **都不用：先别动。** `stopReason=lost` / liveness `unverifiable` 时原 agent 可能仍在跑，**既不授权发信也不授权重试**；先 `worker-show` 判断，不确定就报告不确定。
    ⚠️ 常见错答：把 lost 当成 failed，直接重试或发信催——它可能还在干活。

16. **不能，会被拒。** 原文 `Creation flags (--name, --repo, --base-branch, --display-name, --comment, --setup) are rejected for current/existing worktrees.` 这六个只给 `new-child` / `new-top-level` 用。
    ⚠️ 常见错答：「习惯上都带上，反正会忽略」——是被拒，不是被忽略。

17. **不是。** `state` 是 **Dispatch** 的态，取值集合是四个：`succeeded` / `stopped` / `failed` / `ready`（2026-11-26 本机实测 12 条记录里出现 `succeeded` 11 / `failed` 1；**条数会随库增长漂移，别背数字，背「四个值」这个集合**）。Task 六态是 `pending / ready / dispatched / completed / failed / blocked`——`succeeded`、`stopped` 都不在其中。（复验：`orca orchestration worker-list | grep -o 'state=[a-z]*' | sort | uniq -c`）

18. **不算重试，是新建一个 Task。** `--spec creates a new one`；`--retry-of` 必须配 `--task <失败的那个>`（原文 `--retry-of needs --task naming the failed Task`），且不继承位置，`--on / --worktree / --agent`（或 `--terminal`）四组都要重述。所以只有两条路：**不动 spec 去重试**，或**放弃重试链按新 Task 派**。
    ⚠️ 常见错答：以为「改好 spec + 同一个 `--retry-of`」= 重试；实际上 `--spec` 会把它变成另一个 Task。

19. **不能。** 字段是**常见**不是通则：本机实测 12 条 Dispatch 里有 1 条根本没有 `terminal=` 字段（比例会变，**关键是有反例存在，不是比例多少**）。判据是命令被拒：`worker-read --dispatch <id> --source terminal` → `error: archive_unavailable: Worker Dispatch <id> has no terminal output; read it with --source auto or --source transcript.`（复验：`orca orchestration worker-list | grep 'state=' | grep -vc 'terminal=structworker'`）
    ⚠️ 常见错答：「记录里有 structworker_ 就说明有终端」——同一个错被三个不同模型犯过。

20. **不是一回事。** `--environment` 决定**这条命令连哪个 Orca**（`local` 或已配对 server 的 id/name）；`--on` 决定 **worker 落在哪个 server**（原文 `--on selects only the worker server; the Run and this command remain on the current Orca server.`）。两个维度不互斥，可以同时给；`--on` 也不保证文件可达（第 4 题）。
    ⚠️ 常见错答：把 `local` 当成 `--on` 的取值——`--on` 取的是 `saved-environment`。

21. **`worker-abandon`。** `worker-stop` 真的停：关它的 agent 终端（`closed_agent_terminal`）、连同它启动的 helper 一起停。`worker-abandon` 原文是 `Retains all possibly-live resources and performs no process or filesystem action.`——**只隔离、不碰进程**，用在「我不确定它是不是还活着」的场合。两者都不删工作区。收尾清理用 `worker-release`（幂等）。
    ⚠️ 常见错答：以为 abandon 也会停进程，于是重复 kill；或反过来说不清与 release 的区别。

22. **九种**，原文：`Valid --type values: status, dispatch, worker_done, merge_ready, escalation, handoff, decision_gate, question, heartbeat.`
    `worker_done` 必须带 `--outcome succeeded|failed`；**`worker_done` 和 `heartbeat` 不能发给群组**（它们是精确到 Dispatch 的信号）。
    ⚠️ 常见错答：只答三种（handoff / question / status）——那是 bot 间交接的三种，不是 `--type` 的全部。

23. **不能。** `waitingOnHuman=unknown` 是**常态**（实测 failed / stopped / succeeded 记录全是 unknown），它不能当证据。要看 `worker-show --dispatch <id> **--full**` 里的 **`observation.agentWait`**：非空才是真在等人（并带证据来源 hook / prompt-text / title），`null` 是 Orca 看过、没在等。普通 `--json` 看不到这个字段。
    ⚠️ 常见错答：拿 unknown 当「在等人」去找人拍板；或反过来当「没人等」去催它。

---

## 判分

- 23 题全对：bot 记住了这套东西，可以放心让它派活
- 错在 1/2/3/5/6/13/14/16/17/18/20/22 这类事实题：说明它在凭记忆答，让它去读 `~/.orca/docs/orca-map/orca-map.md`
- 错在 7/11/12/15/19/21/23 这类「含糊题」：说明它记住了结论但没理解区别，最危险——这种会让它拿错判据去冤枉 worker
