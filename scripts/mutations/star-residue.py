p="docs/orca-workflow.html"; s=open(p,encoding="utf-8").read()
old="</body>"
assert old in s
s=s.replace(old,"<p>**这是 Markdown 星号残留**</p>"+old,1)
open(p,"w",encoding="utf-8").write(s)
