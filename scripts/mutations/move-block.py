p="README.md"; s=open(p,encoding="utf-8").read()
B="<!-- grading:begin · 本块由 standards/grading.md 生成，勿手改；要改先改数据源再跑 scripts/apply-grading.py -->"; E="<!-- grading:end · 以上由 scripts/apply-grading.py 写入 -->"
i=s.find(B); j=s.find(E)+len(E)
assert i>0 and j>i
block=s[i:j]
open(p,"w",encoding="utf-8").write((s[:i]+s[j:]).rstrip()+chr(10)*2+block+chr(10))
