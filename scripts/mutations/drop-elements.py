p="README.md"; s=open(p,encoding="utf-8").read()
old="4. **枚举值**：把完整取值列出来"
assert old in s, "drop-elements: 枚举值行没找到（样本过期？）"
s=s.replace(old,"4. **枚举值**：随便写",1)
open(p,"w",encoding="utf-8").write(s)
