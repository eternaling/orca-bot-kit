# docs/ — 定版地图

这个目录是 Orca 结构的**事实所在**。仓库根目录的 `README.md` 是这个包的使用说明，本文件是这份地图自己的清单。

| 文件 | 是什么 | 冲突时 |
| --- | --- | --- |
| `orca-map.md` | **唯一事实来源**：四组全景 + 术语表 + 主路 8 步 + 三条岔路 + 8 条已核口径 + 三条硬限制 + 参数取值 + 命令面 + 维护段 | 以它为准 |
| `orca-map.html` | **由 md 自动生成**的完整网页（`node scripts/build-html.js`），带版本与指纹，勿手改 | 与 md 必然同步 |
| `orca-panorama.html` | 全景**示意图**（手工）：身份与对话 / 协调与调度 / 文件与场地 / 跟踪 / 术语表 / 已核口径 | 仅表结构，**可能落后** |
| `orca-workflow.html` | 流转**示意图**（手工）：主路 8 步 + 三条岔路 + 要不要开 worker | 同上 |
| `QUIZ.md` | 23 道自测题（**只有题目**）；判据在仓库根目录 `templates/self-test-key.md` | — |
| `reviews/` | 三轮独立评审 + 两轮自查的过程记录，回答「为什么是现在这个说法」 | 只作参考，不作依据 |

## 定版信息

- 包版本：见仓库根目录 `VERSION`（当前 `2.1.0`）
- 定版日期：2026-11-26
- 事实基准：**Orca 1.4.278**（`orca bot list` / `orca repo list` / `orca automations list` / `orca orchestration worker-show` / `agent-context --json` 实测）
- 升级或判据变更的经过见仓库根目录 `CHANGELOG.md`
- **瞬时值不写进文档**（bot 个数、项目数、automation 数、工作区根目录）：一律现查

## 三类 HTML 怎么管

- **`orca-map.html`（生成，勿手改）**：改完 `orca-map.md` 跑 `node scripts/build-html.js`。
  `check.sh` 会重新生成一遍逐字比对，不同步直接失败。这就是「内容漏抄」的防法。
- **`orca-panorama.html` / `orca-workflow.html`（手工示意图）**：只有在**结构关系**变了才需要动。
  它们带「可能落后」声明，不承担事实准确性的责任；`check.sh` 会校验该声明存在。
  结构也靠同一套机械检查兞底：标签配对、`var()` 有无 fallback、`100vh`、Markdown 星号残留。
## 改之前

读仓库根目录 `README.md` 的「维护」一节。同步清单只在那里写一份，别处引用它、不要各自枚举。
