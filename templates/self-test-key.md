# 自测题判据（dispatch-worker 末尾那道题）

题：一次派发失败了，你想把它重试到另一台机器，顺便把 spec 写清楚一点。
（1）重试还挂在原来那个 Task 上吗？（2）哪些参数必须重新给？（3）如果坚持「换机器 + 改好的 spec」，该怎么做？

## 满分要点（缺一即不满分）

1. **（1）答「不能同时」**：改了 spec 就是新建 Task，不算重试原 Task。
   引 `--spec creates a new one`。
2. **（2）四组参数全列**：`--on` / `--worktree` / `--agent`（或 `--terminal`），不继承 placement；
   引 `does not inherit placement; repeat the intended --on/worktree and --agent/terminal choices`。
   并指出 `--retry-of` 必须配 `--task <失败的那个>`。
3. **（3）给决断，不是给折中**：**要么放弃重试链、按新 Task 派；要么不动 spec 去重试。**
   如果答案里出现「改 spec + `--retry-of` 挂回原 Task」，**直接判错**。
4. **必须指出 `--item` 与 `--on` 互斥**（`It can't be combined with --on.`）——
   这题问的就是「重试到另一台机器」，而 SOUL 要求结果先落 item，两者一撞就明白了。
5. **必须给一条能真跑的命令**（哪怕不真跑，要写清会看到什么回执：`state=ready` + `dispatchId=ctx_…`）；
   纯文字结论、不给命令的，最多半分。
6. 加分：远程不能 `current`（`Remote current is invalid.`），远程可用 exact remote selector / `new-child` / `new-top-level` 三选（后两者需远程 `--repo`）。

## 「假装会答」的三种长相（任一条出现即不及格）

- 「`--retry-of` 会继承原来的机器和工作区，只改 `--on` 就行」
- 「改了 spec 照样 `--retry-of` 挂回原 Task」
- 只答「会重试」不给参数、不提 `--terminal`、不提 `--item`/`--on` 冲突

## 为什么判据要放在这个文件

放在技能文件里，答案就印在题下一屏，抄相邻两行就能满分，**检不出「没读过原文」**。
这份文件不会被自动注入上下文，所以必须先真读 `--help` 或本文档才答得出来。
