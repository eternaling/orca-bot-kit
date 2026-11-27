p="standards/grading.md"; s=open(p,encoding="utf-8").read()
lines=[l for l in s.split(chr(10)) if "枚举值" not in l]
assert len(lines) < len(s.split(chr(10))), "weaken-source: 没找到枚举值行"
open(p,"w",encoding="utf-8").write(chr(10).join(lines))
