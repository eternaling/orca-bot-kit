p="templates/self-test-key.md"; s=open(p,encoding="utf-8").read()
old="# 第二部分：判分口径"
assert old in s, "rename-section: 目标标题没找到"
# 改成完全不含「第二部分」的名字，才能真正触发「找不到该小节」分支
s=s.replace(old,"# 二、怎么判分",1)
open(p,"w",encoding="utf-8").write(s)
