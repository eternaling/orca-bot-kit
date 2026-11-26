# orca-bot-kit

**当前版本 `1.2.1`** · 事实基准 **Orca 1.4.278** · [CHANGELOG](CHANGELOG.md) · [ROADMAP](ROADMAP.md)

**给 Orca bot 用的调优包。** 任何 Orca bot 读到这个仓库，就知道活该怎么派、worker 该怎么看、哪些说法是错的。

它不是教程，是一套**可验伪的判据**：每条规则都能用一条 `orca` 命令或一句 CLI 原文当场验真伪。核不出来的，不写进来。

> 适用对象：跑在 [Orca](https://github.com/) 里、会派 worker 的 bot（pi / claude / codex … 任意 agent）。
> 不装也能用——读到「30 秒速记」那一节就够上手；想长期用就照「安装」一节做。

---

## 30 秒速记（不安装也够用）

七句话，每句都能验：

1. **先判断要不要开 worker。** 能当场验证的小事自己做；要隔离、跑很久、并行、独立评审，才开。不是硬门槛。
2. **派之前先确认对方够得到料**：目标机的文件、工具、agent 类型、模型。`--on` **只换 worker 所在的 server，不保证它读得到那台机器的目录**。
3. **一个工作区只放一个写手。** 要独立第二意见，另开 reviewer——写的人不该自己判过。
4. **派完就结束回合，不轮询。** 但要分清结局：成功 / 失败 / 等人类回答（healthy，不是失败）/ 没读到料却照样交付。
5. **验收看证据不看说法**：实际改动 + 测试证据 + 剩余事项。判断它有没有真读原文，硬证据是 `orca orchestration worker-read --dispatch <id> --source transcript` 里的原话。
6. **`stopReason=lost` 先别动。** 原 agent 可能还在跑，此时既不授权发信、也不授权重试——先 `worker-show` 看清再说。
7. **重试 ≠ 复制。** `--retry-of` 要配 `--task <失败的那个>`，且 `--on / --worktree / --agent（--terminal）` 四组都要重述。**改了 spec 就是新建 Task，不算重试**（`--spec creates a new one`）。

三条最常被说错的事（都会让人形成错判）：

| 错说法 | 实际 |
|---|---|
| 「worker 没有终端」 | 有的承载形态没有**可交互终端窗格**，但不是没有终端资源。判据：`worker-read --source terminal` 被拒。 |
| 「`--on` 换机器，文件自然读得到」 | `--on` 只决定 worker 落在哪个 server，不保证文件可达。 |
| 「有 `structworker_…` 字段就说明有终端」 | 那是**常见**不是通则，实测有整条记录没这个字段。 |

---

## 安装

把内容和技能装进本机 Orca 的标准位置。装上之后，`skills/orca-map` 与 `skills/dispatch-worker` 才能正常解析它们指向的路径。

**Windows（PowerShell）**

```powershell
.\scripts\install.ps1 -BotName "my-bot"
```

**手动（任意平台）**

```bash
# 1) 事实源与浏览图 → 本机定版目录
mkdir -p ~/.orca/docs/orca-map
cp docs/orca-map.md docs/orca-panorama.html docs/orca-workflow.html docs/QUIZ.md ~/.orca/docs/orca-map/

# 2) 技能 → 你的 bot 家目录（skills/<name>/SKILL.md）
BOT=~/.orca/bots/<你的 bot 目录>
mkdir -p "$BOT/skills/orca-map" "$BOT/skills/dispatch-worker" "$BOT/memory"
cp skills/orca-map/SKILL.md "$BOT/skills/orca-map/"
cp skills/dispatch-worker/SKILL.md "$BOT/skills/dispatch-worker/"

# 3) 自测判据（放在 memory/ 下，不被自动注入上下文）
cp templates/self-test-key.md "$BOT/memory/"
```

装完做两件事：

1. 在你 bot 的 `SOUL.md` 里加一句指针（「派活与交付」这类小节）：
   > 结构与口径见 `~/.orca/docs/orca-map/orca-map.md`（唯一事实来源）。派活清单见 `skills/dispatch-worker`。内容不确定时读 md，不要凭记忆。
2. 跑一遍自测：`docs/QUIZ.md` 23 题，答案在后半段。

---

## 自测（怎么知道你真学会了）

`docs/QUIZ.md` 共 **23 题**，覆盖四组概念、调度链、主路 8 步、三条岔路、几个必错的参数陷阱。

**判分标准比题目更严格**：
- 只答结论不算过——要指出这条结论**依据哪句 CLI 原文，或者用哪条命令能验**
- 出现「改了 spec 还挂回原 Task」「`--retry-of` 会继承原来的机器」这类答案，直接不及格
- 23 题全对 = 可以放心让它派活

判据（答案要点）在 `templates/self-test-key.md`。**它故意不放进技能文件**——放进去就成了抄答案，检不出「没读过原文」。

---

## 内容三份，怎么分工

| 位置 | 放什么 | 权威性 |
|---|---|---|
| `docs/orca-map.md` | **唯一事实来源**：四组全景 + 术语表 + 主路 8 步 + 三条岔路 + 8 条已核口径 + 三条硬限制 + 参数取值 | 冲突时信它 |
| `docs/orca-panorama.html` / `docs/orca-workflow.html` | 同一内容的两张图，自包含、无外部依赖，浏览器直接开 | md 的手工渲染副本 |
| `docs/QUIZ.md` | 23 道自测题 + 答案 | 考题 |

两个技能是**索引不是正文**：
- `skills/orca-map` —— 文件在哪、8 条口径的主题、什么时候读什么
- `skills/dispatch-worker` —— 动手清单（必查 5 项 / spec 四样 / 派发命令 / 岔路动作 / 验收 / 收尾）

这样分工是刻意的：**同一说法只存一份详文**。以前把正文抄进技能，两处各写一份，改一处必漏一处，漂移过好几轮。

---

## 版本与迭代

知识包也要有版本，不然你分不清手里的判据是不是已经过期。

**版本号在根目录 `VERSION`，语义按「会不会让人做错事」定**（不是软件那套功能/兼容）：

| 位 | 什么时候升 | 意味着 |
|---|---|---|
| **MAJOR** | 判据被推翻或重写 | 照旧版做会做错事，**必须重学** |
| **MINOR** | 新增判据 / 新增命令覆盖 / 新增题目 | 旧结论仍对，只是不够全 |
| **PATCH** | 错字、措辞、出处补齐 | 结论不变 |

**两个升级触发器**（缺一不可）：

1. **发现判据错了** —— 立即升，旧说法同时删干净（不要「保留但标注已废弃」两套并存）
2. **Orca 自己升级了** —— 文档里的 CLI 行为是照 `1.4.278` 核的。Orca 升级后，涉及 CLI 的判据要**重核一遍**：`orca agent-context --json` 拿最新 schema，逐条对。核实后判据没变就不升版本，只在 CHANGELOG 记一句「已对账 X.Y.Z，无变化」。

### 怎么知道该重核了：`drift.sh`

不要靠人记得。跑：

```bash
./scripts/drift.sh            # 0=无漂移  1=有原文消失(判据可能失效)  2=Orca 版本变了
./scripts/drift.sh --verbose  # 额外打出每条命中在哪
```

它把 `scripts/drift-checks.txt` 里那 21 条**关键 CLI 原文**逐条拿去当前 Orca 的
`agent-context --json` 与 `skills get orchestration` 里找，找不到就报。
外加比对 `orca-baseline.txt`（对账时的 Orca 版本）与当前 `orca --version`。

**为什么必须单独一个脚本**：`check.sh` 只查本仓库自身是否自洽（标签、题数、版本号），
它**看不见外部 CLI 变了**。判据过期是静默的——文档看着一切正常，但引用的原文已经不存在了。

它已经抓到过一次：清单里原本写着「`read it with --source auto or --source transcript`」，
而实际原文是 `Read output with worker-read --source auto or --source transcript, which always work; …`。
那是我凭记忆记岔的句子——脚本一跑就露了。

升级步骤：改内容 → `./scripts/check.sh`（会核对 `VERSION` 与 CHANGELOG 首节）- 加 CHANGELOG 一节 → 改 `VERSION` → commit → `git tag vX.Y.Z` → `git push --tags`。

想知道下一步要改什么，看 [ROADMAP.md](ROADMAP.md)。

---

## 维护

改**任意一份**后固定做三步：

1. **全局搜旧说法** —— 改了什么词，`grep` 整个仓库确认别处没有旧说法
2. **数一遍数量词** —— 标题写「四条 / 两种 / 9 个」，对着内容数一遍
3. **改一处就同步全部** —— 同步清单就是这一句，别处一律引用它、不要各自枚举：
   **`docs/orca-map.md` / `docs/orca-panorama.html` / `docs/orca-workflow.html` / `docs/QUIZ.md` / `README.md`（根目录那份） / `skills/orca-map/SKILL.md` / `skills/dispatch-worker/SKILL.md`**

这三条不是形式。历史自查 13 处错里 6 处源于漏做前两步，第 7 处是同步清单本身被抄漏。

跑机械检查（两份 HTML 都要过）：

```bash
./scripts/check.sh
```

要求：`tags OK` / `var无fallback 0` / `100vh False` / 无 Markdown 星号残留，并且 `QUIZ.md` 的标题数字 = 题区编号项数 = 答案区编号项数。

改完提交时请在 `CHANGELOG.md` 记一行：**改了什么说法、为什么**。

---

## 目录

```
orca-bot-kit/
├── README.md                  ← 你正在读的（人看；也适合 bot 先扫一眼）
├── AGENTS.md                  ← agent harness 会自动读的落点（比 README 更直接）
├── CHANGELOG.md               ← 什么时候改了什么说法
├── ROADMAP.md                 ← 已知缺口与下一步
├── VERSION                    ← 包版本
├── orca-baseline.txt          ← 对账时的 Orca 版本（drift.sh 拿它比）
├── LICENSE                    ← MIT
├── docs/
│   ├── orca-map.md            ← 唯一事实来源
│   ├── orca-panorama.html     ← 全景图
│   ├── orca-workflow.html     ← 流转图
│   ├── QUIZ.md                ← 23 题 + 答案
│   ├── README.md              ← 这个目录的文件清单与定版信息
│   └── reviews/               ← 历史评审记录（为什么是现在这个说法）
├── skills/
│   ├── orca-map/SKILL.md      ← 索引
│   └── dispatch-worker/SKILL.md  ← 派活动作清单
├── templates/
│   └── self-test-key.md       ← 自测判据（别放进技能文件）
└── scripts/
    ├── install.ps1            ← 装进某个 bot
    ├── check.sh               ← 机械检查（仓库自洽）
    ├── drift.sh               ← Orca 版本漂移监测（外部 CLI 是否变了）
    └── drift-checks.txt       ← 那 21 条关键 CLI 原文清单
```

---

## 这些结论哪来的

不是凭空写的，是三轮独立评审 + 两轮自查打出来的，过程记录在 `docs/reviews/`：

- 一审（gpt-6-luna）10 条，对质后定为 9 条独立问题
- 二审 5 条（3 事实 + 2 技术缺陷）
- 自查两遍共 13 处，主要是「一处改了别处没改」和「标题/数量词与实际不符」
- 三方交叉审计三轮，专门抓「改了副本忘定版」「技能里存了第二份正文」

**最有价值的一条教训**写在 `skills/dispatch-worker` 的坑清单里：worker 交回的「实测数字」必须自己复现一遍——曾有一份报告写着「实测 100 条记录」，用同一条命令跑出来只有 12 条。

## License

MIT
