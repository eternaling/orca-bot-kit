# 自测判据（答题者不要看这个文件）

> **这是判分的答案，不是学习材料。** 要自测就只读 `docs/QUIZ.md` 的题目区，
> 答完再回来对。提前看了就失去了自测的意义。
>
> 判分的标准比「答案对不对」更严，但**不是要求逐字拄原文**。
> 每题答案必须至少含**一处可核对的具体依据**，以下四类任一即可：
>
> 1. 逐字原文片段（如 `It can't be combined with --on.`）
> 2. 一条能真跑的命令（如 `worker-read --dispatch <id> --source terminal`）
> 3. 具体的字段名或参数名（如 `observation.agentWait`、`--worktree`）
> 4. 完整的枚举值（如九种 `--type`、Task 六态）
>
> **只写结论、四项都没有的，不算过。** 反之，只要四项占一样，就不因为「没抄引导语」而扣分
> （例：第 22 题把九种 type 全列出来了，即使没写 `Valid --type values:` 这个前缀也算过）。

---

# 第一部分：`docs/QUIZ.md` 那 23 题的答案

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

10. **派完就结束回合，不守着**；但要能区分它的三种去向。判断用 `orca orchestration worker-show --dispatch <id>`：
    看 `state`（Dispatch 四值 `ready / succeeded / failed / stopped`）与 `stage`；
    想知道它是**在等人类**而不是在跑，加 `--full` 看 `observation.agentWait`（非空=在等人）。
    验完就结束回合，不 sleep、不轮询。

11. `pi/claude/codex/cursor/antigravity/muse/zcode/opencode/opencode2` 是 **Agent（执行程序）类型**，不是 worker 的种类。而且 CLI 原文是 `such as` 引出的**开放列举（非穷尽）**——`pi` 就不在那句名单里却实际在用，别把它当全部种类。worker 按两条轴看：**执行程序**和**承载形态**（结构化聊天 / 普通 terminal）。定模型与深度用 `--model provider/id` + `--effort off/minimal/low/medium/high/xhigh/max`。

12. **确认对方够得到料**：机器、文件、工具、agent 类型、模型。
    跳过它会撞到**可复现的具体错误**：① 远程用 `current` → `Remote current is invalid.`；
    ② 以为 `--on` 能带文件 → 它只选 worker 所在 server，不保证目录可达；
    ③ worker 没读到料却照写报告（本机实例：一个自称在云端没设备权限，**其实就在本机 bot home**）。

13. **四值：`current` / `selector` / `new-child` / `new-top-level`。远程不能用 `current`**，原文 `Remote current is invalid.`
    ⚠️ 常见错答：「就 current 和 new-child 两种」——漏了 `selector` 和 `new-top-level`。

14. **不能。** 原文 `It can't be combined with --on.`
    想既挂 Item 台账又指定 `--on <server>`，具体做法是**分两次**：先用带 `--on` 的命令派出去，
    拿到 `dispatchId=ctx_…` 后再 `orca bot item link <n> dispatch:<id>` 挂账。
    （不要用 `item comment` 代替——它只往台账写一行字，不会把这个 worker 关联进去。）

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

---

# 第二部分：判分口径

## 判分

- 23 题全对：bot 记住了这套东西，可以放心让它派活
- 错在 1/2/3/5/6/13/14/16/17/18/20/22 这类事实题：说明它在凭记忆答，让它去读 `~/.orca/docs/orca-map/orca-map.md`
- 错在 7/11/12/15/19/21/23 这类「含糊题」：说明它记住了结论但没理解区别，最危险——这种会让它拿错判据去冤枉 worker

---

# 第三部分：`skills/dispatch-worker` 末尾那道题

## 满分要点（缺一即不满分）

1. **（1）答「不能同时」**：改了 spec 就是新建 Task，不算重试原 Task。
   引 `--spec creates a new one`。
2. **（2）四组参数全列**：`--on` / `--worktree` / `--agent`（或 `--terminal`），不继承 placement；
   引 `does not inherit placement; repeat the intended --on/worktree and --agent/terminal choices`。
   并指出 `--retry-of` 必须配 `--task <失败的那个>`。
3. **（3）给决断，不是给折中**：**要么放弃重试链、按新 Task 派；要么不动 spec 去重试。**
   如果答案里出现「改 spec + `--retry-of` 挂回原 Task」，**直接判错**。
4. **必须指出 `--item` 与 `--on` 互斥**（`It can't be combined with --on.`）——
   这题问的就是「重试到另一台机器」，而 SOUL 要求结果先落 item，两者一撞就明白了。
5. **必须给一条能真跑的命令**（哪怕不真跑，要写清会看到什么回执：`state=ready` + `dispatchId=ctx_…`）；
   纯文字结论、不给命令的，最多半分。
6. 加分：远程不能 `current`（`Remote current is invalid.`），远程可用 exact remote selector / `new-child` / `new-top-level` 三选（后两者需远程 `--repo`）。

## 「假装会答」的三种长相（任一条出现即不及格）

- 「`--retry-of` 会继承原来的机器和工作区，只改 `--on` 就行」
- 「改了 spec 照样 `--retry-of` 挂回原 Task」
- 只答「会重试」不给参数、不提 `--terminal`、不提 `--item`/`--on` 冲突

## 为什么判据要放在这个文件

放在技能文件里，答案就印在题下一屏，抄相邻两行就能满分，**检不出「没读过原文」**。
这份文件不会被自动注入上下文，所以必须先真读 `--help` 或本文档才答得出来。
