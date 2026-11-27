import re
p="README.md"; s=open(p,encoding="utf-8").read()
m=re.search(r"(\d+)(\s*个用例)", s)
assert m, "case-count: README 里找不到「N 个用例」"
n=int(m.group(1))
s=s.replace(m.group(0), f"{n+1}{m.group(2)}", 1)
open(p,"w",encoding="utf-8").write(s)
