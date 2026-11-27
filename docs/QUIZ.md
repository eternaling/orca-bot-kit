# 考 bot：Orca 地图 23 问

**共 23 题**，分五批补入（1–10 基础、11–12 加分、13–15 参数陷阱、16–20 审计补考、21–23 命令面对账）。
编号是连续的 1–23，分节只是记录「什么时候补的」，不是难度分级。

**答案不在这个文件。** 判据文件叫 `self-test-key.md`，位置见文末（仓库里与装完之后不一样）。
它是给**判分的人**看的。要自测：先只读本文件的题目、把 23 题答完，再去对判据。

**答案要留痕**：写到 `<你的家目录>/memory/self-test-answers-YYYYMMDD.md`，再去对判据。
理由：判分是自判自，没有留痕就无法事后验证「真的先答后看」——而这套包最在意的恰是这一点。
**无留痕视为未自测。**

判分的标准比「答对没答对」更严（与 README、判据同一份，由 `standards/grading.md` 生成）：

<!-- grading:begin · 本块由 standards/grading.md 生成，勿手改；要改先改数据源再跑 scripts/apply-grading.py -->
每题必须给出**一处可核对的依据**，四类任一即可：

1. **原文片段**：逐字引一段 CLI 原文（如 `It can't be combined with --on.`）
2. **能跑的命令**：一条能真跑、结果可看的命令（如 `worker-read --dispatch <id> --source terminal`）
3. **字段名 / 参数名**：具体到字段或参数（如 `observation.agentWait`、`--worktree`）
4. **枚举值**：把完整取值列出来（如九种 `--type`、Task 六态）

只写结论、四类都没有的，**不算过**；反之只要占一样就不因「没抄引导语」扣分。

**枚举型题必须答全**：判据列出 N 条（如第 12 题的三个错误 + 五项清单、第 17 题的六个状态），
**缺一即算不过**。只答对一半的，别按「有依据」放过——「有依据」和「依据覆盖全」是两件事。

**留痕与污染声明**：
- 答案写到 `<你的家目录>/memory/self-test-answers-YYYYMMDD.md`，**无留痕视为未自测**。
- 先答后看靠自觉，机制上只能做到这些：建议**每答 5 题 append 一次**（留下递进的时间序列），
  判分者在打开判据**之前**先记下答案文件的 mtime。
- **之前读过判据的（例如装过旧版再重跑），必须在答案文件开头声明污染**，并逐题标注
  哪些答案来自判据记忆、哪些来自文档；**判分只认后者**。不声明的话，二次回归的分数是虚高的。

（本节之外不再另述判分标准；看到 `grading:begin/end` 标记请勿手改——改 `standards/grading.md` 后跑 `scripts/apply-grading.py`。）
<!-- grading:end · 以上由 scripts/apply-grading.py 写入 -->

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
10. 派完 worker 之后，bot 该守着还是干别的？如果要确认它是在跑、在等人、还是已结束，用哪条命令、看哪些字段？

## 加分题（更难，考它会不会含糊）

11. `--agent` 那些选项（pi/claude/codex…）是什么东西的种类？worker 的「种类」又是什么？
12. 主路第 3 步是干嘛的？跳过它，会撞到哪几个**具体可复现**的错误？

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

答完了去哪对？判据文件叫 `self-test-key.md`，它的位置取决于你怎么拿到这份 QUIZ：

- **在仓库里读**：`templates/self-test-key.md`（仓库根目录下）
- **装到自己身上之后**：`<你的 bot 家目录>/memory/self-test-key.md`

（这里不写相对路径：安装会改变目录结构。早先写过一次相对路径，装完就成了死链。）
