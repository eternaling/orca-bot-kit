#!/usr/bin/env bash
# 机械检查：两份 HTML 的结构 + QUIZ 数量自洽 + Markdown 星号残留
# 用法：在仓库根目录跑 ./scripts/check.sh   退出码 0 = 全过
set -u
cd "$(dirname "$0")/.." || exit 1
fail=0

echo "== 1/5 两份 HTML 结构 =="
for f in docs/orca-panorama.html docs/orca-workflow.html; do
  python - "$f" <<'PY'
import re,sys
p=sys.argv[1]
s=open(p,encoding='utf-8').read()
bad=[(t,len(re.findall(r'<%s[ >]'%t,s)),s.count('</%s>'%t)) for t in
     ['div','table','thead','tbody','tr','p','ul','ol','li','style','span','b','code']
     if len(re.findall(r'<%s[ >]'%t,s))!=s.count('</%s>'%t)]
nofb=len(re.findall(r'var\(--[a-z0-9-]+\)',s))
star=re.findall(r'\*\*[^*<]{1,25}\*\*',s)
ok = (not bad) and nofb==0 and ('100vh' not in s) and (not star)
print(f"  {p}: tags={'OK' if not bad else bad} var无fallback={nofb} 100vh={'100vh' in s} 星号={len(star)} -> {'OK' if ok else '失败'}")
sys.exit(0 if ok else 1)
PY
  [ $? -ne 0 ] && fail=1
done

echo "== 2/5 QUIZ 与判据数量自洽 =="
python - <<'PY'
import re,sys
q=open('docs/QUIZ.md',encoding='utf-8').read()
k=open('templates/self-test-key.md',encoding='utf-8').read()
m=re.search(r'地图\s*(\d+)\s*问',q)
title=int(m.group(1)) if m else -1
def seq_count(text):
    nums=[int(x) for x in re.findall(r'^(\d+)\.\s', text, re.M)]
    seq=[]
    for n in nums:
        if n==len(seq)+1: seq.append(n)
    return len(seq)
nq=seq_count(q)
part=re.split(r'^# 第二部分', k, flags=re.M)
na=seq_count(part[0]) if len(part)>1 else -1

# 泄漏检测（三道，每道都能单独抓到一类）
# ① 标题级：题目文件不得出现「答案/判据/参考/解答」类小标题
head_leak = re.findall(r'^#{1,6}\s*.*(?:答案|判据|参考|解答|key|answer)', q, re.M | re.I)

# ② 滑动窗口指纹：对每条答案取所有 24 字窗口（步长 8），任一命中即泄漏。
#    为什么不用「首 24 字」——改写开头、后面照抄就全躲过了（v1.5.1 的实际漏检）。
bodies = []
for line in part[0].split('\n'):
    s2 = line.strip()
    if re.match(r'^\d+\.\s', s2):
        b = re.sub(r'^\d+\.\s*', '', s2).replace('**', '')
        if len(b) >= 24:
            bodies.append(b)
win_hits = []
for b in bodies:
    for i in range(0, max(1, len(b) - 24 + 1), 8):
        w = b[i:i+24]
        if len(w) >= 24 and w in q:
            win_hits.append(w)
            break

# ③ 相似度兜底：题目文件里任意 200 字段落，与某条答案去标点后的相似度 > 0.85 也算泄漏
def norm(t):
    return re.sub(r'[\s\W_]+', '', t)
qn = norm(q)
sim_hits = []
for b in bodies:
    bn = norm(b)
    if len(bn) < 60:
        continue
    step = 100
    for i in range(0, max(1, len(bn) - 200 + 1), step):
        seg = bn[i:i+200]
        if len(seg) < 200:
            break
        if seg in qn:
            sim_hits.append(b[:24])
            break
        # 允许少量差异：逐 20 字切片命中率 > 85%
        pieces = [seg[j:j+20] for j in range(0, 200, 20)]
        found = sum(1 for pc in pieces if pc in qn)
        if found / len(pieces) > 0.85:
            sim_hits.append(b[:24])
            break

hits = win_hits or sim_hits
leak = bool(head_leak) or bool(hits)
ok = title==nq==na and title>0 and not leak
why = head_leak or win_hits or sim_hits
print(f"  标题={title} 题目={nq} 判据答案={na} 泄漏={'是 -> ' + str(why[:2]) if leak else '否'} -> {'OK' if ok else '失败'}")
sys.exit(0 if ok else 1)
PY
[ $? -ne 0 ] && fail=1

echo "== 3/5 文档里不该有 Markdown 星号（HTML 会原样显示） =="
if grep -n '\*\*[^*<]\{1,25\}\*\*' docs/*.html >/dev/null 2>&1; then
  echo "  HTML 里有 ** 残留 -> 失败"; fail=1
else
  echo "  OK"
fi

echo "== 4/5 版本一致性（VERSION 与 CHANGELOG 首节） =="
python - <<'PY'
import re,sys
v=open('VERSION',encoding='utf-8').read().strip()
s=open('CHANGELOG.md',encoding='utf-8').read()
m=re.search(r'^##\s*v(\d+\.\d+\.\d+)',s,re.M)
top=m.group(1) if m else None
ok = bool(re.fullmatch(r'\d+\.\d+\.\d+',v)) and v==top
print(f"  VERSION={v!r} CHANGELOG首节={top!r} -> {'OK' if ok else '不一致（改版本时要同时改两处）'}")
sys.exit(0 if ok else 1)
PY
[ $? -ne 0 ] && fail=1

echo "== 5/5 生成物与示意图 =="
# 内容型 HTML 必须与 md 完全同步（真漂移检测：重新生成一遍比对）
if command -v node >/dev/null 2>&1; then
  node scripts/build-html.js --check
  [ $? -ne 0 ] && { echo "  ✗ orca-map.html 与 md 不同步（跑 node scripts/build-html.js）"; fail=1; }
else
  echo "  ⚠ 没装 node：⚠ 这一项没验（不是通过）。装了 node 的机器上必须为 OK"
fi
# 两份手工示意图必须带「可能落后」的声明，否则会被误当成权威内容
for f in docs/orca-panorama.html docs/orca-workflow.html; do
  if grep -q "手工绘制的结构示意图" "$f"; then
    echo "  ✓ $f 已声明是示意图"
  else
    echo "  ✗ $f 缺「手工示意图」声明（会被误当权威内容）"; fail=1
  fi
done

echo
if [ $fail -eq 0 ]; then echo "全部通过 ✓"; else echo "有失败项 ✗"; fi
exit $fail
