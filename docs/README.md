# docs/ — 定版地图

这个目录是 Orca 结构的**事实所在**。仓库根目录的 `README.md` 是这个包的使用说明，本文件是这份地图自己的清单。

| 文件 | 是什么 | 冲突时 |
| --- | --- | --- |
| `orca-map.md` | **唯一事实来源**：四组全景 + 术语表 + 主路 8 步 + 三条岔路 + 8 条已核口径 + 三条硬限制 + 参数取值 + 维护段 | 以它为准 |
| `orca-panorama.html` | 全景图：身份与对话 / 协调与调度 / 文件与场地 / 跟踪 / 术语表 / 已核口径 | 信 md |
| `orca-workflow.html` | 流转图：主路 8 步 + 三条岔路 + 要不要开 worker | 信 md |
| `QUIZ.md` | 23 道自测题 + 答案；判据在仓库根目录 `templates/self-test-key.md` | — |
| `reviews/` | 三轮独立评审 + 两轮自查的过程记录，回答「为什么是现在这个说法」 | 只作参考，不作依据 |

## 定版信息

- 包版本：见仓库根目录 `VERSION`（当前 `1.2.0`）
- 定版日期：2026-11-26
- 事实基准：**Orca 1.4.278**（`orca bot list` / `orca repo list` / `orca automations list` / `orca orchestration worker-show` / `agent-context --json` 实测）
- 升级或判据变更的经过见仓库根目录 `CHANGELOG.md`
- **瞬时值不写进文档**（bot 个数、项目数、automation 数、工作区根目录）：一律现查

## 两份 HTML 是手工渲染副本

它们没有生成器，改 md 后必须人肉同步。这是已知的结构性风险，靠 `../scripts/check.sh` 兜底：
标签配对、`var()` 有无 fallback、`100vh`、Markdown 星号残留，两份都要过。

## 改之前

读仓库根目录 `README.md` 的「维护」一节。同步清单只在那里写一份，别处引用它、不要各自枚举。
