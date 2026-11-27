p="README.md"; s=open(p,encoding="utf-8").read()
old="- 23 题全对 = 可以放心让它派活"
add="- 那四类你挑着用，不用都凑。"
assert old in s
s=s.replace(old, old + chr(10) + add, 1)
open(p,"w",encoding="utf-8").write(s)
