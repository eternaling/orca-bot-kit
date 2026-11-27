# 考 bot：Orca 地图 23 问

**共 23 题**，分五批补入（1–10 基础、11–12 加分、13–15 参数陷阱、16–20 审计补考、21–23 命令面对账）。
编号是连续的 1–23，分节只是记录「什么时候补的」，不是难度分级。

**答案不在这个文件。** 判据在仓库根目录 `templates/self-test-key.md`，
它是给**判分的人**看的。要自测：先只读本文件的题目、把 23 题答完，再去对判据。

判分的标准比「答对没答对」更严：**只给结论不算过，要给出 CLI 原文、或一条能验的命令。**

用法：随便挑几条问 bot，看它答得对不对。**答案在最后，先别看。**

题目都挑的是 bot 历史上真答错过的坑，不是常识题。

---

## 题

1. worker 有终端吗？
2. Run 会调度 worker、会挑机器吗？
3. Item 的状态是不是「Planned → In progress → Waiting → Needs you」一条线走下来？
4. `--on <server>` 是不是意味着 worker 能读到那台机器上的目录？
5. `--retry-of` 重试时，会沿用上次的机器、工作区、agent（或复用的 `--terminal`）吗？哪些参数必须重新给？
6. Git worktree 一定有自己的分支吗？
7. 怎么判断一个 worker 到底有没有真读文件？
8. 一个结构化 worker 的聊天窗口被关掉，那次派发会怎样？
9. bot 之间要交接活，有哪几种方式，分别什么意思？
10. 派完 worker 之后，bot 该守着还是干别的？

## 加分题（更难，考它会不会含糊）

11. `--agent` 那些选项（pi/claude/codex…）是什么东西的种类？worker 的「种类」又是什么？
12. 主路第 3 步是干嘛的？跳过它会有什么后果？

## 补考题（2026-11-26 新增）

13. `--worktree` 有几种取值？能不能在远程机器上用 `current`？
14. `worker-start` 里 `--item` 和 `--on` 能一起用吗？
15. `worker-show` 显示 `stopReason=lost`、liveness `unverifiable`，该重试还是该发信催它？

## 二轮补考（2026-11-26 清理轮新增，前置审计提过但一直没考到）

16. 目标是 `current` 或已有工作区，还能带 `--name / --repo / --base-branch / --display-name / --comment / --setup` 吗？
17. `worker-show` 打出来的 `state=stopped` 是 Task 的状态吗？Task 到底有哪六态？
18. 想把失败那次改好 spec，再用 `--retry-of` 重派，算重试吗？`--retry-of` 必须配哪个参数？
19. 一条 dispatch 记录里有 `structworker_…` 资源标识，能说明它有可交互终端吗？判据是什么？
20. `--environment local` 和 `--on <server>` 是一回事吗？

## 三轮补考（2026-11-26 对账 1.4.278 命令面时新增）

21. worker 卡住了，你想「先隔离住、但别动它的进程」，用 `worker-stop` 还是 `worker-abandon`？两者区别是什么？
22. `send --type` 一共几种？`worker_done` 必须带什么？哪两种类型不能发给群组？
23. 你只跑了 `worker-show --json`，看到 `waitingOnHuman=unknown`，能断定它不在等人吗？该怎么查？

---

---

答完了？去对 `../templates/self-test-key.md`（第一部分是这 23 题的答案，第二部分是判分口径）。
