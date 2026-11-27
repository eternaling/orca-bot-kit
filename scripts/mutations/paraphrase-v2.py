p="README.md"; s=open(p,encoding="utf-8").read()
old="- 23 题全对 = 可以放心让它派活"
add="- 判分时给个原文引用或者跑条命令就行，别的不用。"
assert old in s
s=s.replace(old, old + chr(10) + add, 1)
open(p,"w",encoding="utf-8").write(s)
