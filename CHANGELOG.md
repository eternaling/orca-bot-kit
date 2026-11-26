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
