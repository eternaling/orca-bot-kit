# Orca 地图（Markdown 版 · 定版 2026-11-26）

**这份是唯一事实来源。** 两份 HTML（`orca-panorama.html` / `orca-workflow.html`）是它的浏览版，
`QUIZ.md` 和 `README.md` 引用它，`skills/orca-map` 与 `skills/dispatch-worker` 只留指针——
**口径详文、参数取值、维护清单都只在本文件此处一份**，别处不存第二份（存过，然后漂移了）。

事实基准：本机 local，2026-11-26 核对。快照数字会过期，引用前现查：

```bash
orca bot list          # 5 个 bot
orca repo list         # 9 行，含 ~ 家目录，不是 9 个代码项目
orca automations list  # 0 个
```

---

# 第一部分：全景（有哪些东西）

## ① 身份与对话

| 东西 | 是什么 |
| --- | --- |
| **Bot ×5** | 长期身份。jarvis / local / night / ali / nas，各有 SOUL + 记忆 + 职责。 |
| **Home Chat** | 每个 bot 一个常驻对话，别人派活落这里。 |
| **子聊天** | 隔离另一个话题，不是新建了 bot 或工作区。 |

**bot ↔ bot 是交接，不是划界：**

| 类型 | 含义 |
| --- | --- |
| `--type handoff` | 连责任一起交出去，对方负责交付和答复 |
| `--type question` | 只请教，自己仍负责收尾 |
| `--type status` | 只同步背景，不转移责任 |

## ② 协调与调度（一条调度链）

```
Run → Task → Dispatch → Worker
```

箭头只表示先后顺序，不是包含关系。

| 环节 | 是什么 |
| --- | --- |
| **Run** | 命名空间 + 收件箱。自己不调度、不挑机器。不绑 Run 时 `worker-start` 会自己建一个。 |
| **Task** | 要做的事。状态：`pending / ready / dispatched / completed / failed / blocked`。 |
| **Dispatch** | 一次派发的记录（`ctx_…`）。同一个 Task 可以重试多次、有好几个 dispatch。它的 `state` 是 `ready` / `succeeded` / `failed` / `stopped`（四值，**与 Task 六态不是一套**，见参数取值与自测第 17 题） |
| **Worker** | 受监督的执行实例，由某个 Agent 启动。 |

**Worker ≠ Agent。** Worker 是执行实例，Agent 是启动它的执行程序：`pi / claude / codex / cursor / antigravity / muse / zcode / opencode / opencode2`。所谓「worker 分好几种」，其实是 Agent 类型不同，加上承载形态不同。

**承载形态至少两种：**

| 形态 | 表现 | 注意 |
| --- | --- | --- |
| 结构化（聊天）承载 | 不提供普通可交互的 terminal 窗格，在 Orca 里表现为**一个聊天窗口** | 关掉这个窗口 → 该次 dispatch 失败：`lastError="Terminal closed by operator request"` |
| 普通 terminal 承载 | 有可交互终端 | 也可以用 `--terminal` 直接复用已有终端 |

## ③ 文件与场地

| 东西 | 是什么 | 实例 |
| --- | --- | --- |
| **Repo** | 项目本体，主工作树就在原路径 | `D:/night/gitea/night-flow` |
| **工作区根目录** | 全局设置，新工作区默认建在这里 | `D:\night\orca\workspaces`（2026-11-26 从 C 盘改到 D 盘） |
| **Git worktree** | 独立工作目录；通常检出一个分支，也可处于 detached HEAD | `…/night-flow/wallet-subscription` |
| **Folder 工作区** | 不是 git 也能开 | `C:\Users\night\.orca\bots\local-bot` |

注意：

- 「一个分支一个目录」只描述 Git worktree；主工作树留在 repo 原路径，新工作区才在根目录下。
- worker **不是必须**新建工作区（可用 `--worktree current` / 已有工作区）。

## ④ 跟踪

| 东西 | 是什么 |
| --- | --- |
| **Item 台账** | 跨回合跟踪。开着时是这几个状态之一：Planned（还没动）/ In progress（在干）/ Waiting（等外部）/ Needs you（等你决定）——**不是一条必须按顺序走的流水线** |
| **Automation** | 按时间或事件触发一次后续。能监听什么取决于 `trigger-options`（很多要接 GitHub 等连接器） |

Item 和 Automation 都是**辅助跟踪手段**，不是活着的必经层级，也不是开 worker 的前提。

## ⑤ 术语一句话对照

| 词 | 一句话 |
| --- | --- |
| Run | 命名空间 + 收件箱。自己不管调度、不挑机器。 |
| Task | 要做的事。六个状态见上。 |
| Dispatch | 一次派发的记录（`ctx_…`）。 |
| Worker | 受监督的执行实例。按执行程序（Agent）和承载形态两条轴描述。 |
| Agent | 启动 worker 用的执行程序类型。 |
| Worktree | 文件位置。新建工作目录 / 已有工作区 / 当前工作区都行。 |
| Item | 跨回合台账，给人看的进度和责任；不强制、不等于任务本身。 |
| Automation | 到点或遇到事件时启动一次。 |

---

# 第二部分：流转（活怎么走）

## 主路 8 步

| 步 | 谁 | 做什么 | 关键点 |
| --- | --- | --- | --- |
| 1 | **你** | 说需求 + 完成标准 + 依赖的本机条件 | 要读本机文件、要联网、要某个 CLI 权限，先说 |
| 2 | Bot | 选执行方式：自己干 / 开 worker / 交给另一个 bot | 小而可当场验证 → 自己做；要隔离、跑久、并行、独立评审 → 开 worker。不是硬门槛 |
| 3 | Bot | **派发前先确认对方够得到料** | `--on` 选的是 worker 所在的 Orca server，Run 和发起命令仍在当前 server；**不保证它读得到另一台机器上的目录** |
| 4 | Bot | 写 spec 并派发 | 范围、不可动的东西、验收证据、交付格式；模型用 `--model provider/id` + `--effort off…max`；目标是 `current` 或已有工作区时**不带** `--name/--repo/--base-branch/--display-name/--comment/--setup`（会被拒）；`--item` **不能与** `--on` 同用 |
| 5 | Worker | 在**选定的**工作区里干（新建 / 已有 / current 都可能）：改 → 验证 → 报告 | 不一定都开 PR；一个工作区一个写手；多人协作先划清文件所有权 |
| 6 | Bot | 不等轮询：靠 Orca 通知，但要分清四种结局 | **成功 → 第 7 步**；**其余三种**（失败 / 等人类回答 / 能力不符）分别走三条岔路 |
| 7 | Bot | 验收：看实际改动 + 测试证据 + 剩余事项 | 按风险决定要不要 reviewer；验收不过回第 4 步，不重开一件事 |
| 8 | **你** | 看结论 + 拍板；点头之后才清理场地 | `orca worktree rm` 由 bot 执行，你只管点头 |

真实案例：读本机两份 HTML → 选执行方式 → 先确认它读得到 → 派发 → 验收 → 清理。**第一次就是第 3 步没验，白跑三次**（一次自称无权限照写、两次承载被关掉）。

## 三条岔路

### 岔路一：失败 / 卡死

检查 Dispatch 的状态与原因，再决定（注意：`worker-show` 里的 `state` 是 **Dispatch** 的状态：`ready` / `succeeded` / `failed` / `stopped`，**不是** Task 的六态）：

- **`stopReason=lost` / liveness `unverifiable`：先别动。** 原 agent 可能仍在跑，此时**既不授权发信也不授权重试**，先 `worker-show` 判断，不确定就报告不确定
- `state=failed` 或 `stopReason=exited`：进程退出已确认 → 看原因 → 需要就 `worker-stop`，再按下一条重试
- **重试 ≠ 复制**：`--retry-of` 配 `--task <失败的那个>`，且**不继承位置**，`--on / --worktree / --agent（--terminal）` 四组都要重述
- **改了 spec，就是新建一个 Task，不算重试**（CLI：`--spec creates a new one`）→ 只有两条路：**要么放弃重试链按新 Task 派，要么不动 spec 去重试**
- 三条兜底：**换 agent / 换机器 / 自己接手**

**`worker-stop` 与 `worker-abandon` 不是一回事**：

| | 行为 |
|---|---|
| `worker-stop --dispatch <id>` | 真的停：关它的 agent 终端（`closed_agent_terminal`）、连同它启动的 helper 一起停；**从不删工作区** |
| `worker-abandon --dispatch <id>` | **只隔离、不碰进程**：原文 `Retains all possibly-live resources and performs no process or filesystem action.` 用在「我不确定它是不是还活着」的场合 |
| `worker-release --dispatch <id>` | 完事后的清理：只关那个 coordinator 自己开的终端，可重复调（幂等） |

**要取消一个 Task**（想真取消的，不要等它跑完）：先 `worker-stop` 或 `worker-abandon` 把 worker 处理掉，再 `task-update --id <task> --status failed --result cancelled`；以后想重做，`worker-start --retry-of` 会重开它（CLI 原文就给了这个顺序）。

**不盲目重启。** 回到主路第 3–4 步，或直接收口。

### 岔路二：等你确认 / 要授权

worker 停下等人类回答时是 **healthy，不是失败**。该回答就回答（`orca orchestration reply --id <msg_id> --body <text>`），该你拍板就变成 Item 的 Needs you。回答后它继续；否则挂在你身上。

**怎么判它真在等人**（别靠猜）：`worker-show --dispatch <id> --full` 里的 **`observation.agentWait`**——它非空就说明 worker 挂在一个只有人能回答的 prompt 上，并带证据来源（`hook` / `prompt-text` / `title`）；`null` 表示 Orca 看过、没在等人。

⚠️ 表面字段不可靠：`waitingOnHuman=unknown` 是**常态**（实测 `failed` / `stopped` / `succeeded` 记录全是 unknown），不能当「在等人」的证据；`agentWait` 也只在 `--full` 里出现，普通 `--json` 看不到。

还有一类不是「等人」而是「要授权」：worker 弹权限请求时用 `deny --dispatch <id> --prompt <approval_id> --reason <text>` 拒掉它——**worker 会带着这个理由继续走**，不是卡死，别去 stop。

### 岔路三：能力不符

它没读到原文却照样写报告。

- **最硬的证据是 transcript 自述**（`orca orchestration worker-read --dispatch <id> --source transcript` 能看到它原话）
- 「要求它引用只有读过才知道的细节」是**降级判据**——引不出只说明它没给可验证证据，不能反过来当成「肯定没读」
- 这**不是 Orca 放错机器**：出事的 workspace 都是本机 bot home，问题是 worker 自我误判能力后仍然交付
- 处置：停掉，改派能碰到料的 agent/机器

## 要不要开 worker（不绝对，看这几种情形）

| 情形 | 怎么选 |
| --- | --- |
| 查一下、回一句、改一行 | 自己做，派发的开销比活大 |
| 要动项目代码、要跑很久、要隔离 | 开 worker（新工作区或已有工作区都行） |
| 几件互不相干的事 | 并行开，但并发量按当前容量控，不要一次铺满 |
| 要独立第二意见 | 按风险决定开不开 reviewer，不是每次都开 |
| 要等外部（CI / 别人评审 / 到点） | 建 automation 等待 + 留 Item 记账；能用什么触发看 `trigger-options` |
| 整件事该另一个 bot 负责 | `--type handoff` 连责任一起交；只是请教用 `question`，只同步用 `status` |

---

# 已核对的口径（别再说错）

1. **Run 不管调度**：`A Run is a namespace and home inbox. It never schedules or places workers.`
2. **Task 六个状态**：`pending / ready / dispatched / completed / failed / blocked`（原文在 `orca orchestration task-update` 的 notes：`Valid --status values: pending, ready, dispatched, completed, failed, blocked.`——`--help` 里只写占位符，所以别拿 help 当依据）
3. **不能写「worker 没有终端」**：CLI 说 `Not every worker has a terminal` = 没有**可交互终端窗格**；判据是 `worker-read --source terminal` 被拒（`archive_unavailable: … has no terminal output`）。结构化承载**常见**带 `structworker_…` 标识，但不是通则，别拿字段存在当证据
4. **worker 的「种类」不是 Agent 清单**：`--agent` 是 `such as`（开放列举，非穷尽）
5. **`--on` 只选 worker 所在的 Orca server**，不保证文件可达（完整取值与原文见「参数取值」表，此处不重复）
6. **判断 worker 是否真读了文件**：硬证据是 transcript 原话，不是「引不出细节」
7. **Item 状态不是流水线**
8. **bot 之间靠 `handoff` / `question` / `status` 交接**，不按项目划死边界。但这三种只是 `send --type` 的一部分——共有**九种**，完整清单见下面「命令面」

## 另外三条硬限制（不计入上面 8 条）

- **`--worktree` 远程限制**：**远程不能用 `current`**（`Remote current is invalid.`）；远程能用的是 exact remote selector / `new-child` / `new-top-level`（后两者需远程 `--repo`），四个取值见下一节
- **`--item` 与 `--on` 互斥**：`It can't be combined with --on.` —— 派到别的机器那个命令就挂不了账，只能事后再挂（写法见下一节）
- **`stopReason=lost` 先别动**：原 agent 可能仍在跑，`unverifiable` 既不授权发信也不授权重试；处置顺序见岔路一

## 参数取值（全文档唯一一份；会随版本变，引用前 `orca orchestration worker-start --help` 重验）

用法行原文（节选）：

```text
(--task <task_id> | --spec <text> | --spec-file <path|->) [--keep-open] [--on <saved-environment>]
[--worktree <current|selector|new-child|new-top-level>] (--agent <agent> | --terminal <handle>) …
```

| 参数 | 取值 / 原文依据 |
| --- | --- |
| `--environment <selector>` | **这条命令连哪个 Orca**：`local`，或已配对 server 的 id / name。原文 `--environment local pins it here.`；`Without --on a start never picks a server: it runs on the Orca this command reaches.` |
| `--on <saved-environment>` | **只选 worker 落在哪个 server**：`--on selects only the worker server; the Run and this command remain on the current Orca server.` → 与 `--environment` 是**两个维度**，可以同时给；它不保证文件可达（口径 5） |
| `--worktree` | **问「几种取值」答四种**（`current` / `selector` / `new-child` / `new-top-level`；`selector` 是一**类**不是一种）；selector 形如 `name:<x>` / `path:<x>` / `id:<repo-id>::<path>` / `folder:<id>` / `branch:<x>` / `issue:<n>` / `identity:<…>` / `active`（= `current`） |
| `--agent` / `--terminal` | **二选一**（用法行 `(--agent <agent> \| --terminal <handle>)`）。`--agent` 是 `such as` 开放列举（口径 4）；`--terminal` 复用已发出的终端 handle，此时**不给 `--worktree`**（原文 `When reusing --terminal, omit --worktree to start in that terminal's own workspace`）。读产出不受承载形态影响，一律 `worker-read --source auto` |
| `--model` + `--effort` | `--model provider/id`；`--effort` 必须配 `--model`，取 `off / minimal / low / medium / high / xhigh / max`（pi 映射到它的 thinking level）；`--model`、`--effort` 都不能与 `--terminal` 同用 |
| `--item <n>` | 与 `--on` 互斥（硬限制 2）；派到别的机器就事后再挂：`orca bot item link <n> dispatch:<id>`（`item comment` 只写字，不算挂账） |
| `--retry-of <dispatch_id>` | 必须配 `--task <失败的那个>`（原文 `--retry-of needs --task naming the failed Task`）；`--spec` 会新建 Task、位置不继承，处置在岔路一 |
| `--keep-open` | 默认干完自己关：`Finished workers close on their own unless started with --keep-open`；新建工作区那两种还要看回执里的 `keepOpenByDefault` |
| 创建类参数 | `--name` / `--repo` / `--base-branch` / `--display-name` / `--comment` / `--setup`：原文 `Creation flags (…) are rejected for current/existing worktrees.` 只对 `new-child` / `new-top-level` 用（见主路第 4 步） |

---

# 命令面（Orca 1.4.278 实测：`orca orchestration` 31 个子命令）

前面的章节讲**概念与判断**；这一节讲**你手边到底有哪些命令**。不常用的命令不必背，但要知道它存在——否则会绕着弯做事。

## 你日常用的（十个）

| 命令 | 干什么 |
|---|---|
| `worker-start` | 派一次活（参数在上一节） |
| `worker-show` | 看一个 dispatch 的状态；**加 `--full` 才有 `observation`** |
| `worker-read` | 读它的产出（`--source auto` 最常用） |
| `worker-list` | 列你的 worker |
| `worker-stop` / `worker-abandon` / `worker-release` | 三种收场，见岔路一那张表 |
| `reply` | 回答 worker 的问题（`--id <msg_id> --body <text>`） |
| `send` | 给 worker / 别的 bot / Run 发信（类型见下） |
| `inbox` / `check` | 看收件箱；`check` 是消费式的（读过的批次会被标记，下次只给新的） |

## 容易漏掉的（存在但常被忘记）

| 命令 | 什么时候用 |
|---|---|
| `worker-keep-open` | 不想让它干完就关（取消自动释放的那个例外）；`worker-release` 可手动清掉这个例外 |
| `deny` | 拒掉 worker 的权限请求，**它带着理由继续跑**（不是杀它） |
| `task-create` / `task-list` / `task-update` | 自己建任务、看状态、改状态（含「取消」那套） |
| `dispatch` | 把一个 Task 派到**已有终端**（与 `worker-start` 新建不同）；`--dry-run` 可以先看 preamble |
| `dispatch-show` / `request-show` | 查 dispatch 上下文；**不确定上一次改动有没有生效**时用 `request-show`（只读，安全） |
| `gate-create` / `gate-resolve` / `gate-list` | **决策门**：把一个 Task 卡在“等人拍板”上。比在聊天里问一句更结构化 |
| `run-create` / `run-use` / `run-current` / `run-list` / `run-show` | 管 Run（命名空间 + 收件箱） |
| `reset` | 清 orchestration 状态（`--all` / `--tasks` / `--messages`），破坏性，少用 |

## `send --type` 有九种（不是三种）

原文：`Valid --type values: status, dispatch, worker_done, merge_ready, escalation, handoff, decision_gate, question, heartbeat.`

| 类型 | 含义 |
|---|---|
| `handoff` | 连责任一起交出去（对别的 bot 用这个） |
| `question` | 只请教，自己仍负责收尾 |
| `status` | 只同步，不转移责任 |
| `worker_done` | worker 报告完成，**必须带 `--outcome succeeded\|failed`** |
| `escalation` | 升级：卡住 / 要授权 / 失联 |
| `merge_ready` | 分支可合了 |
| `decision_gate` | 需人拍板 |
| `dispatch` | 派发通知 |
| `heartbeat` | 心眺 |

两个坑：`worker_done` 和 `heartbeat` 是**精确到 Dispatch** 的信号，不能发给群组；不传 `--to` 就用该 Dispatch 的 Run 收件箱。

## 两个容易误会的 scope

- **`worker-list` 默认只看当前绑定的 Run**（原文 `Without --run the list is scoped to the Run bound to the calling terminal`），最多 100 条。所以「我只有 12 个 worker」很可能只是这个 Run 里 12 个。
- **`inbox` 不传 `--terminal` / `--run` 就是整台 Orca 的全部邮箱**，范围大得多。

## 两个已退役的命令

`coordinator-start` / `coordinator-stop` **不再有副作用**，调用只会返回一句提示（“改用 Run / Task / worker-start 那套基元”）。看到别人（或旧文档）叫你用它们，直接跳过。

---

# 维护

改**任意一份**后固定做三步：

1. **全局搜旧说法**：改了什么词，`grep` 整个文件确认别处没有旧说法
2. **数一遍数量词**：标题写「四条 / 两种 / 9 个」，对着内容数一遍
3. **改一处就同步全部**。权威清单就是这一句，别处一律引用它、不要各自枚举：
   **`orca-map.md` / `orca-panorama.html` / `orca-workflow.html` / `QUIZ.md` / `README.md` / `skills/orca-map` / `skills/dispatch-worker`（外加 `MEMORY.md` 里对应的那一行）**

这三条不是形式——前两轮自查 13 处错里 6 处源于漏做（一处改了别处没改、标题「看这四条」实际 6 行），第三次是同步清单本身被抄漏。

机械检查（也只有这一份，在 `~/.orca/docs/orca-map` 下跑，两份 HTML 都要过）：

```bash
for f in orca-panorama.html orca-workflow.html; do python -c "
import re,sys
s=open(sys.argv[1],encoding='utf-8').read()
bad=[(t,len(re.findall(r'<%s[ >]'%t,s)),s.count('</%s>'%t)) for t in
 ['div','table','thead','tbody','tr','p','ul','ol','li','style','span','b','code']
 if len(re.findall(r'<%s[ >]'%t,s))!=s.count('</%s>'%t)]
print('tags',bad or 'OK'); print('var无fallback',len(re.findall(r'var\(--[a-z0-9-]+\)',s))); print('100vh','100vh' in s)
" $f; done
grep -n '\*\*' orca-panorama.html orca-workflow.html || echo 'markdown residue: none (OK)'   # 有输出就是 bug
```

要求：两份都 `tags OK` / `var无fallback 0` / `100vh False`，且 `grep '\*\*'` 无输出。
