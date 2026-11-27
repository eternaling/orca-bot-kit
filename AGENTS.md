# AGENTS.md

给会自动读这个文件的 agent harness。人请读 `README.md`。

## 你可能是被一句话叫过来的

如果用户只给了你一个仓库地址加一句「把它装到你自己身上」，那他要的是：
照 `README.md`「把仓库丢给 bot，让它自己装」那节的步骤装到你自己身上，然后自测。
装完要能说出：装到哪几个路径、23 题错了几题、说明书哪里没讲清。

## 你在哪

这是一个 **Orca bot 调优包**。它不含可运行的程序，只有判据、清单和一份事实源。

## 你要做的事

1. **要知道 Orca 的结构** → 读 `docs/orca-map.md`。它是**唯一事实来源**；`docs/orca-map.html` 是它自动生成的完整网页（必然同步），两份示意图（panorama / workflow）只表结构关系、**可能落后**。冲突时一律信 md。
2. **要派 worker / 盯 worker / 验收** → 读 `skills/dispatch-worker/SKILL.md`（动作清单），细节去 md 的「三条岔路」。
3. **要确认自己学会了** → 答 `docs/QUIZ.md`（23 题），判据在 `templates/self-test-key.md`。先答再看。
4. **要改这里的任何说法** → 先读 `README.md` 的「维护」一节，按那三步做，再跑 `./scripts/check.sh`。
5. **怀疑判据过期了（比如 Orca 升级过）** → 跑 `./scripts/drift.sh`。它把本文档依赖的 21 条 CLI 原文逐条拿到当前 Orca 里核对；退出码 1 就是有原文消失了。

## 硬约束（别违反）

- **不要往 `skills/` 里抄正文。** 技能是索引；详文只在 `docs/orca-map.md`。理由是历史上抄成两份后反复漂移。
- **不要凭记忆回答 Orca 的结构问题。** 读 md，或者用 `orca ... --help` 现查。
- **引用 Orca 行为时给出可验的依据**：CLI 原文，或一条能跑的命令。给不出就别断言。
- **瞬时值一律现查**（bot 个数、项目数、automation 数、工作区根目录）。文档里不存这些数字。
- **自测时不许先看答案。** 先答完 23 题再对 `templates/self-test-key.md`；提前看了就失去了自测的意义。

## 内容地图

| 你要什么 | 读哪 |
|---|---|
| 五组概念是什么关系、活怎么流 | `docs/orca-map.md` 前半（全景 + 主路 8 步 + 三条岔路） |
| 别再说错的 8 条口径 + 3 条硬限制 | `docs/orca-map.md` 后半 |
| 参数取值（`--worktree` / `--on` / `--item` / `--terminal` …） | `docs/orca-map.md`「参数取值」一节 |
| 动手派活的步骤 | `skills/dispatch-worker/SKILL.md` |
| 自测题 | `docs/QUIZ.md` |
| 想在网上或浏览器里看完整内容 | `docs/orca-map.html`（自动生成） |
| 为什么是现在这个说法 | `docs/reviews/` 与 `CHANGELOG.md` |
| 下一步要改什么 | `ROADMAP.md` |
| 判据会不会已过期 | 跑 `./scripts/drift.sh` |
