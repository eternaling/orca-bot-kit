---
name: dispatch-worker
description: >-
  派活给 worker 时照这个走。触发：要派 worker、起个 worker、worker-start、给 Codex/Claude/pi 派活、
  把活拆开并行、开个新工作区干活、盯 worker 结果、worker 失败/卡死/lost/stopped 怎么办、
  验收 worker 的产出、判断 worker 到底读没读文件、判断它有没有终端、要不要开 worker。
---

# 派 worker 的清单

这是 Orca 地图（主路 8 步 + 三条岔路）的可执行版本。口径只存一份，**本文件不再存第二份**。

那份地图在哪（按顺序找，第一个存在的就用）：`~/.orca/docs/orca-map/orca-map.md`（安装后的标准位置），或仓库里的 `docs/orca-map.md`。

## 派之前必查 5 项

⚠️ 这 5 项**横跨主路第 2–4 步**，不是只对应第 3 步（别写成「全对应第 3 步」）：

| # | 查什么 | 对应主路 |
|---|---|---|
| 1 | **值不值得派**：能当场验证的小事自己做 | 第 2 步 |
| 2 | **东西在哪台机器**：本机是默认，可写 `--environment local` 钉住；另一台机器用 `--on <saved-environment>`（已保存的配对 server，不是 ssh 地址）。⚠️ 两个**不同维度**，可以同时给；取值与原文见 md「参数取值」 | 第 3 步 |
| 3 | **材料可达**：要读的文件在目标机的哪个绝对路径；长文档一律内联原文 | 第 3 步 |
| 4 | **agent 与模型**：`--agent`（`such as`，开放）；`--model provider/id`；`--effort off/minimal/low/medium/high/xhigh/max`（七个值；省略号写法不能当枚举依据） | 第 4 步 |
| 5 | **场地**：`--worktree` 四值；一个工作区只放一个写手 | 第 4 步 |

**`--on` 的两个硬限制**：① 它只换 worker 所在的 server，**不保证读得到另一台机器的目录**；② **远程不能用 `current`**，远程可用 **exact remote selector / `new-child` / `new-top-level`** 三选（后两者需远程的 `--repo`）。原文与参数取值集合全在 md「参数取值」+「另外三条硬限制」，本文件不存副本。

## 参数速查

**不在这里。** `--terminal` / `--item`×`--on` / `--worktree` 四值 / 创建类参数禁带 / `--retry-of`
全部只存 `orca-map.md`「参数取值」一节，用法行原文也在那里。跑命令前对着那节核一眼。

## spec 四样 + 报告路径

```text
<任务一句话>

背景：<已确认的事实，不必重查的写明「不必重查」>
要你做的：<分条>
硬性要求：<反编造：每条结论必须引用只有读过才知道的细节，引不出就标「未核对」>
约束：<只读/可改范围/不许碰什么>
完成证据：<结论写哪里；最终回复里必须给出什么>
```

- 一条活两份报告对比时，**路径必须不同**，否则后写的覆盖先写的
- 临时报告一律放 `Temp`，不往 bot 家目录丢
- `--spec-file <path>` 传 spec，不要用 heredoc
- **别强求它写本机绝对路径**：有的模型会卡在「我写不了别的机器的路径、只肯写自己 workspace」上原地打转。折中：结论写进**最终回复**，文件报告当可选项。

## 派发命令

```bash
orca orchestration worker-start --environment local \
  --agent pi --model nightcc-codex/gpt-6-luna --effort high \
  --worktree new-child --name <短词> --repo <项目> \
  --item <n> --spec-file <spec路径> --task-title "<标题>"
```

**派到别的机器就删掉 `--item`**（互斥），改用事后 `orca bot item link <n> dispatch:<id>` 挂上去（不是 `item comment`——comment 只写字，不会把 worker 关联进台账）。

收到回执照着读：`state=ready` 才算起来；`dispatchId=ctx_…` 是后续所有操作的句柄。
**派完立刻结束回合**，不 sleep、不轮询。Orca 会在它结束时叫醒我。

## 三条岔路 → 口径在 md

**处置口径（两套状态名、`lost` 先别动、重试要重述四组、改了 spec 算新 Task）只在
`orca-map.md`「三条岔路」那一节。** 本文件只留动作：

1. `orca orchestration worker-show --dispatch <id>` —— 先看清 `state` / `liveness` / `stopReason`
2. `orca orchestration worker-read --dispatch <id> --source transcript` —— 看它到底干了什么
3. 该停就 `worker-stop --dispatch <id>`；该问就 `orchestration reply`；该重试就按 md 的规则重述四组
4. 主人拍板的，设 Item 的 Needs you

⚠️ 一条最容易搞错、已写进 md 和 QUIZ 的：`worker-show` 的 `state` 是 **Dispatch** 的状态，
不是 Task 的六态；`stopReason=lost` / liveness `unverifiable` 时原 agent 可能还在跑，
此时既不授权发信也不授权重试。

## 验收

- 看**实际改动 + 测试证据 + 剩余事项**，不看它说得多漂亮。
- **不一定都开 PR**：`改→验证→报告` 也算交付完；没有 PR 不等于没干完。
- 判断它**有没有可交互终端**：`worker-read --source terminal` 被拒
  （`archive_unavailable: … has no terminal output; read it with --source auto or --source transcript`）
  → 无终端；读内容一律 `--source auto`。判据与「`structworker_` 字段不算证据」的解释只在 md 口径 3。
- `worker-read` 可能被 `Oversized transcript text was clipped` 截掉尾部（实测 13.7KB 的报告只取到 6.2KB）。拿不到全文就 `orchestration send` 让它**自己写文件**，别跟 cursor 死磕（换来源报 `source_changed`）。
- 按风险决定要不要再开 reviewer；**写的人不该自己给自己判过**。

## 收尾

1. 结果落到 item；需要主人决定就 `--status needs-you`。
2. 验收通过**且**目录不再需要（没有待修复审、没有外部依赖）才清理工作区，**清之前问主人一句**。
3. 清：`orca worktree rm <selector>`。

## 要不要开 worker

那张决策表（自己做 / 开 worker / 并行 / reviewer / 等外部改用 automation / handoff）
只在 `orca-map.md`「要不要开 worker」，行为与它一致，本文件不重列。

## 坑（都踩过）

- **派活前先确认目标文件真的存在**：`ls -la <路径>` 再写进 spec。曾经拿自己编的路径去出方案，现场一查就破。
- **换模型重派同一条活，先 `worker-stop` 旧的**，两个写手写同一份报告会互相覆盖。
- **停之前先看它有没有已经产出**：查报告文件、看 transcript 到哪一步。曾把一份已写完 25KB 的 worker 当「太慢」停掉。
- **别用 `head -N` 截断现查结果**：曾把 5 个 bot 看成 3 个，转头去「纠正」一份其实正确的图。查数量用 `--json` 解析。
- **别把去标签的脏数据当成文档的错**：自己用 `sed` 去标签没处理多行 `<style>`，把 CSS 粘进材料，评审把它当成文档 bug 上报。多行 `<style>` 要用 python 或先 `tr -d '\n'`。
- **长文档评审必须把原文内联进 spec**，只给路径不够。
- **worker 交回的「实测数字」必须自己复现一遍**。踩过：它写了「实测 100 条 Dispatch，succeeded 83 / stopped 14 / failed 2，7 条无 terminal」并当依据写进 QUIZ，我用它给的同一条命令跑出来只有 **12 条**。判据：拿到数字先跑那个命令对一遍，再让它进文档。
- **它可能拿「搜不到」当「无依据」删掉真判据**。踩过：`When reusing --terminal, omit --worktree to start in that terminal's own workspace` 确实在 help 的 Notes 段，它只搜了用法行就说没有依据，把这条删了。验收时要把被删的断言逐条回查原文（用法行搜不到就去 Notes/说明段找）。

## 自测（题在这里，判据不在本文件）

**题**：一次派发失败了，你想把它**重试到另一台机器**，顺便把 spec 写清楚一点。
（1）重试还挂在原来那个 Task 上吗？（2）哪些参数必须重新给？（3）如果你坚持要「换机器 + 改好的 spec」，该怎么做？

**判据**在 `memory/self-test-key.md`，别先看。判分不是「引三句原文」，而是**必须给出一条能真跑的命令**并说明回执长什么样。

---

## 改文档 / 改本文件

步骤、同步清单、两份 HTML 的机械检查脚本**只存 `orca-map.md`「维护」段**。
改本文件也算改文档，照那一份走一遍。
