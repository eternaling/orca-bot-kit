p="templates/self-test-key.md"; s=open(p,encoding="utf-8").read()
old="4. **枚举值**：把完整取值列出来"
assert old in s, "key-part2: 目标行没找到"
s=s.replace(old,"4. **枚举值**：可写可不写",1)
open(p,"w",encoding="utf-8").write(s)
