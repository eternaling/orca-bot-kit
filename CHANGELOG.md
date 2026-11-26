# Changelog

记「改了什么说法、为什么」。日期 + 一句话。说法变了就记，措辞微调不用记。

## 2026-11-26 · 首次发布

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

## 维护约定

1. 改任意一份后跑 `./scripts/check.sh`
2. 同步清单在 `README.md`「维护」一节，别处引用它、不要各自枚举
3. 说法变了就在这里记一行
