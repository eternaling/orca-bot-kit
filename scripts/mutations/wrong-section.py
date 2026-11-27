p="README.md"; s=open(p,encoding="utf-8").read()
old="3. **字段名 / 参数名**：具体到字段或参数（如 `observation.agentWait`、`--worktree`）"
assert old in s, "wrong-section: 字段名行没找到（样本过期？）"
s=s.replace(old,"3. 字段名：自己看着办",1)
open(p,"w",encoding="utf-8").write(s)
