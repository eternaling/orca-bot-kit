p="README.md"; s=open(p,encoding="utf-8").read()
B="<!-- grading:begin · 本块由 standards/grading.md 生成，勿手改；要改先改数据源再跑 scripts/apply-grading.py -->"; E="<!-- grading:end · 以上由 scripts/apply-grading.py 写入 -->"
assert s.count(B)==1
open(p,"w",encoding="utf-8").write(s+chr(10)+B+chr(10)+"旧标准：只要原文即可。"+chr(10)+E+chr(10))
