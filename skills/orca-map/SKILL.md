---
name: orca-map
description: >-
  Orca 的结构地图：bot、chat、Run/Task/Dispatch/worker/agent、worktree 与工作区根目录、
  Item、automation 各是什么，活怎么从 owner 派到 bot 再派到 worker。用于回答
  「Orca 里这些东西是什么关系」「worker 和 bot 什么区别」「怎么派活」「工作区/分支怎么回事」
  「automation 能干嘛」「一个活怎么流转」，以及在派 worker、建工作区、写 spec 前核对口径。
  也用于判断 worker 是否真的读到了材料（转写记录判据）。
---

# Orca 地图

**本文件是索引，不是正文。** 定版地图只有一份在 `C:\Users\night\.orca\docs\orca-map\`，
回答结构类问题前**先读那份**，不要凭记忆，也不要把正文抄回本文件（以前抄过，两边漂移了）。

| 文件 | 是什么 |
| --- | --- |
| `orca-map.md` | **唯一事实来源**：四组全景 + 术语表 + 主路 8 步 + 三条岔路 + 8 条已核口径 + 参数取值与硬限制 + 维护段 |
| `orca-panorama.html` / `orca-workflow.html` | 同一内容的两张浏览图（自包含，无外部依赖）；**冲突时信 md** |
| `QUIZ.md` | 20 道自测题（答案在后） |
| `README.md` | 文件清单与定版信息 |

## 什么时候用

- 主人问 Orca 的结构、层级、某个概念是什么
- 派 worker 之前核对：放哪台机器、用哪个工作区、spec 该写什么（动手清单在 `skills/dispatch-worker`）
- 判断某个说法对不对（例如「worker 没有终端」这种）
- 主人问「这个活该怎么派 / 拆给谁」

## 8 条口径的索引（**详文只在 md「已核对的口径」**）

表里只有主题，**没有措辞**——措辞只存 md 一份，要原文就在那份里取：
`grep -n -A24 '^# 已核对的口径' ~/.orca/docs/orca-map/orca-map.md`

| # | 主题 |
|---|---|
| 1 | Run 不管调度 |
| 2 | Task 六态 |
| 3 | 不能说「worker 没有终端」（含判据与 `structworker_` 的解释） |
| 4 | Worker ≠ Agent |
| 5 | `--on` 只换 server，不保证文件可达 |
| 6 | 真读文件的硬证据（transcript 原话；「引不出细节」只是降级判据） |
| 7 | Item 四态并列，不是流水线 |
| 8 | bot 间交接三种：handoff / question / status |

另有三条硬限制与**参数取值集合**（`--worktree` 四值、`--environment` vs `--on`、
`--terminal` 二选一、`--model`/`--effort`、`--item`×`--on`、`--retry-of`、`--keep-open`、
创建类参数禁带）：全在 md「另外三条硬限制」+「参数取值」两节，本文件不存副本。

## 坑

- 数量与瞬时值（bot 个数、项目数、automation 数、工作区根目录路径）**一律现查**，
  `orca bot list --json` / `orca repo list --json` / `orca automations list`，`--json`
  的结果在 `.result.bots` / `.result.repos` 里（顶层直接 `len()` 会数成 4）。
- `orca repo list` 里有一行是 `~` 家目录，不是代码项目。
- 两份 HTML 是浏览器渲染用的，别把它们的内容当成 CLI 当前状态——状态一律现查。

## 改文档

**步骤与同步清单只在 `orca-map.md`「维护」段**（含两份 HTML 的机械检查脚本）。
本文件只留一句：改的是哪个说法，就去 md 的维护段照单做一遍，别处一律引用它、不要各自枚举。
