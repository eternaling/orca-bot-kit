# Changelog

记「改了什么说法、为什么」。措辞微调不用记，**结论变了必须记**。

版本号见根目录 `VERSION`，规则如下（这是知识包，不是软件，所以语义按「会不会让人做错事」定）：

| 位 | 什么情况升 | 例子 |
|---|---|---|
| **MAJOR** `X.0.0` | **判据被推翻或重写**——照旧版做会做错事，读旧版的人必须重学 | 「`lost` 就该重试」→「`lost` 先别动」；「worker 没有终端」→「没有可交互终端窗格」 |
| **MINOR** `1.Y.0` | 新增判据、新增命令覆盖、新增题目——旧结论仍然成立，只是不够全 | 补「命令面」21 个命令；QUIZ 20→23 题 |
| **PATCH** `1.1.Z` | 错字、措辞、同步修正、出处补齐——**结论不变** | 补 CHANGELOG；补 Task 六态原文出处 |

升级步骤（`scripts/check.sh` 会核对 VERSION 与本节第一条是否一致）：

1. 改内容 → 跑 `./scripts/check.sh`
2. 在本文件顶部加一节，标题带新版本号
3. 改 `VERSION`
4. `git commit` → `git tag vX.Y.Z` → `git push origin master --tags`

**事实基准会过期**：文档里的判据是照 **Orca 1.4.278** 的 `agent-context` schema 核出来的。Orca 升级后，
涉及 CLI 行为的判据要重新核一遍再决定升哪一位——升级本身不算版本变更，判据变了才算。

---

## v1.5.0 · 2026-11-26 · 把答案从题目文件里物理拆出（真实用户测出来的）

拿 v1.4.0 的提示词真测了本机的 `jarvis bot`。它 23 题**内容全对**，但抓出 9 条说明书问题，
其中一条是真实的逻辑冲突：

> 第 5 步叫我只读题目区、不许打开答案区；第 6 步却叫我「去对 templates/self-test-key.md」——
> 而那个文件里只有 dispatch-worker 那道题的判据，**没有 23 题的答案**。
> 照你说的做，我只能判 1 道题，「错了几题」这个问题本身就问不出来。

确实是我的错。原来的自测流程自相矛盾。

**结构改动**：
- `docs/QUIZ.md` 现在**只有题目**（3205 B），文件里不再有任何答案
- `templates/self-test-key.md` 扩成三部分：①23 题答案 ②判分口径 ③dispatch-worker 那道题
- `check.sh` 第 2 项改成三方对齐（标题 = 题目数 = 判据答案数），并新增**泄漏检测**：
  题目文件里出现 `## 答案` 就失败

**按它的另外 6 条反馈一并改了**：
- 提示词里 Windows 没有 `/tmp` → 改成 `mktemp -d` 再 clone
- 明确「docs 与 skills 必须一起装」，只装 skills 会断链（这条原来是隐含的）
- 安装节注明：目标目录已有文件时**覆盖同名、不要清空**
- 标明 SOUL.md 属于 bot 的 owner、**bot 自己不该擅改**，要征得同意（它当时正确地拒改了，这是对的）
- QUIZ 开头写明「共 23 题，分五批补入，编号连续 1–23」，消除"正式只有 10 题"的误读
- 提示词里补一句判分标准：只给结论不算过，要给 CLI 原文或能跑的命令

它自己说：内容 0 错，但有 3 题（6/9/10）只给结论没给验法，按严格标准不达标；
第 10 题它认为本身就不符合「每条结论可验伪」的原则。这个意见我认同，留在 ROADMAP。

## v1.4.0 · 2026-11-26 · 「把仓库丢给 bot，让它自己装」

主人提的用法：与其教人看安装文档，不如把仓库地址 + 一段提示词发给 bot，让它自己装、自己自测。
这比「写给人看的安装说明」更贴近实际使用。

新增 README「把仓库丢给 bot，让它自己装（推荐用法）」：
- 短版提示词（一行，适合执行力强的 bot）
- 完整版提示词（7 步，含「做不到就说、不要猜不要编」、「答题前别读答案区」）
- 说明为什么值得存在：把验收标准变成可执行动作——装好=路径真存在、学会=23 题答对、
  说明书合格=一个没读过的 bot 能自己走完

AGENTS.md 也补一节：如果用户只给了仓库地址加一句「装到你自己身上」，该怎么理解这个请求。
硬约束里加了「自测时不许先看答案」。

## v1.3.0 · 2026-11-26 · 内容型 HTML 改为生成，消灭"手抄漏抄"

原来两份 HTML 是 md 的手工副本。`check.sh` 能查标签结构、星号残留，但**抓不住内容漏抄**——
改 md 忘了同步某句，没人会发现。这是 ROADMAP 里剩下的那条 HIGH。

做法：
- 新增 `scripts/build-html.js`（零依赖，Node）：把 `docs/orca-map.md` 编译成 `docs/orca-map.html`，
  带版本号徽标 + md 指纹 + "不要手改"提示 + 自动目录；支持 `--check`（只比对不写）
- `check.sh` 加第 5 项：**重新生成一遍逐字比对**，md 改了忘生成就直接失败
- 两份手工示意图（panorama / workflow）保留，但加显式声明"手工绘制、可能落后、措辞以 md 为准"，
  `check.sh` 校验该声明存在——防它们被误当成权威内容

发布前实测了失败路径：只改 md 不生成 → check.sh 退出 1；重新生成 → 0；还原 → 0。

## v1.2.1 · 2026-11-26 · 修 CRLF 导致的全量误报

**这个 bug 只在克隆出来的仓库里出现，本地工作副本完全看不出来。**

`drift-checks.txt` 被 git 按 CRLF 检出后，`read` 读到的行尾带 `
`，
而比对材料里没有 `
` → **21 条全部误报「原文消失」**（外加 4 个空行条目，共 25 条）。
同一台机器、同一个 Orca 版本：本地 0 条漂移，克隆 25 条。

修法两处：
- `drift.sh` 逐行剥掉 `
`，并显式跳过空行
- 新增 `.gitattributes` 固定行尾（脚本与清单强 LF，PowerShell 脚本 CRLF）

**教训**：验证「别人能不能用」必须用全新克隆跑，不能只看本地工作副本。
这个 bug 就是端到端克隆验证抓出来的。

## v1.2.0 · 2026-11-26 · Orca 版本漂移监测

新增 `scripts/drift.sh` + `scripts/drift-checks.txt` + `orca-baseline.txt`。

为什么：`check.sh` 只查本仓库自身自洽，**看不见外部 CLI 变了**。判据过期是静默的——文档看着一切正常，引用的原文却已经不存在。

怎么工作：把 21 条关键 CLI 原文逐条拿去当前 Orca 的 `agent-context --json` 与 `skills get orchestration` 里找；
再比对 `orca-baseline.txt` 与 `orca --version`。三条退出码：0 无漂移 / 1 有原文消失 / 2 版本变了。

**发布前已自测三条路径**：正常 → 0；注入假条目 → 1；版本写错 → 2。
顺手抓到一条我自己凭记忆记岔的原文（`--source auto` 那句的开头），已改正。

## v1.1.1 · 2026-11-26

补记 CHANGELOG 本身（v1.1.0 提交时漏了，自查发现）。首版起建立版本体系：`VERSION` 文件 + 语义化 tag。

## v1.1.0 · 2026-11-26 · 按 Orca 1.4.278 实测对账

用 `orca agent-context --json`（419 条命令的机器可读 schema）逐条核对，不靠记忆。发现 `orca orchestration` 有 **31 个子命令**，仓库只覆盖了 10 个。

**新增**：「命令面」一节。`send --type` 实际九种（不是三种）；`worker-stop` / `worker-abandon` / `worker-release` 三者的区别（abandon 原文 `Retains all possibly-live resources and performs no process or filesystem action.`）；取消 Task 的正确顺序；`deny` 之后 worker 会继续跑；`gate-*` / `dispatch*` / `run-*` / `task-*` 的用途；两个 scope 陷阱；`coordinator-start/stop` 已退役。

**修正**：
- 岔路二「怎么判它在等人」改用 `observation.agentWait`（`--full` 才有），不再只靠 `waitingOnHuman`（unknown 是常态）
- 口径 2：Task 六态的原文在 `task-update` 的 notes 里，`--help` 只写占位符
- 口径 8：`handoff/question/status` 只是 `send --type` 的三种，不是全部
- QUIZ 20 → 23 题（补 agentWait / abandon vs stop / 九种 type）

## v1.0.0 · 2026-11-26 · 首次发布

打包自一台 Windows 机器上一轮完整的调优过程。三轮独立评审、两轮自查、三轮交叉审计打出来的结果。

重点修掉的错（每条都是真实踩过的）：

- **「worker 没有终端」** → 改成「没有可交互终端窗格」，判据是 `worker-read --source terminal` 被拒；`structworker_…` 字段是**常见**不是通则
- **`--on` 被当成「换机器文件自然可达」** → 澄清它只决定 worker 落在哪个 server
- **重试与改 spec 混为一谈** → 加了 `--spec creates a new one`：改了 spec 就是新建 Task，不算重试
- **`stopReason=lost` 被并进「失败就重试」** → 改为「先别动，原 agent 可能还在跑」，此时不授权发信也不授权重试
- **`--item` 与 `--on` 互斥没写** → 补上（`It can't be combined with --on.`），并给出事后 `orca bot item link` 的正解
- **远程可用值写成两选** → 实际是三选（exact remote selector / new-child / new-top-level）
- **`--environment` 与 `--on` 被并成二选一** → 拆成两个维度：前者决定命令连哪个 Orca，后者决定 worker 落在哪
- **技能里存了正文第二份** → 技能降为索引，详文只留 `docs/orca-map.md`，这是多次漂移的根因
