#!/usr/bin/env bash
# 机械检查：两份 HTML 的结构 + QUIZ 数量自洽 + Markdown 星号残留
# 用法：在仓库根目录跑 ./scripts/check.sh   退出码 0 = 全过
set -u
cd "$(dirname "$0")/.." || exit 1
fail=0

echo "== 1/6 两份 HTML 结构 =="
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

echo "== 2/6 QUIZ 与判据数量自洽 =="
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

echo "== 3/6 文档里不该有 Markdown 星号（HTML 会原样显示） =="
if grep -n '\*\*[^*<]\{1,25\}\*\*' docs/*.html >/dev/null 2>&1; then
  echo "  HTML 里有 ** 残留 -> 失败"; fail=1
else
  echo "  OK"
fi

echo "== 4/6 版本一致性（VERSION 与 CHANGELOG 首节） =="
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

echo "== 5/6 生成物与示意图 =="
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

echo "== 6/6 判分标准三处一致（限定到各自小节，四要素齐全） =="
python - <<'PY6'
import re,sys

# 四要素：判分标准必须把「依据」限定成这四类。少任何一类 = 只剩原文/命令的旧标准。
NEED = {
    '原文片段': r'原文片段|逐字原文|CLI 原文',
    '能跑的命令': r'能跑的命令|能运行的命令|可运行|能验的命令',
    '字段名': r'字段名|参数名',
    '枚举值': r'枚举值',
}
# 明令禁止的旧口径（只认两类 / 二选一）
BAN = (r'二者之一|两者之一|二选一即可|只认原文或命令|只认原文/命令|仅需原文'
       r'|只给结论不算过|只答结论不算过|依据哪句 CLI 原文|要给 CLI 原文|只需要原文或命令')

def section(text, anchor, stop):
    """取 anchor 之后、stop 之前的那一段（找第一个命中的 stop）"""
    i = text.find(anchor)
    if i < 0: return ''
    j = len(text)
    for s2 in stop:
        k = text.find(s2, i+len(anchor))
        if k >= 0: j = min(j, k)
    return text[i:j]

targets = {
    'README 自测节': (open('README.md',encoding='utf-8').read(), '## 自测', ['## 内容分成', '## 版本与迭代']),
    'QUIZ 前言':     (open('docs/QUIZ.md',encoding='utf-8').read(), '# 考 bot', ['## 题']),
    '判据第二部分':   (open('templates/self-test-key.md',encoding='utf-8').read(), '# 第二部分', ['# 第三部分']),
}

bad = []
for name,(text,anchor,stop) in targets.items():
    seg = section(text, anchor, stop)
    if not seg:
        bad.append(f'{name}: 找不到该小节（标题被改了？）'); continue
    missing = [k for k,pat in NEED.items() if not re.search(pat, seg)]
    if missing: bad.append(f'{name}: 缺 {missing}')
    if re.search(BAN, seg): bad.append(f'{name}: 出现旧口径（{re.search(BAN,seg).group(0)}）')

if bad:
    for b in bad: print('  [FAIL]', b)
    print('  -> 失败')
    sys.exit(1)
print(f'  三处小节各含四要素（{list(NEED)}）且无旧口径 -> OK')
print('  注：这是一致性检查，不做语义判断；改判分标准后仍需人看一遍 diff。')
sys.exit(0)
PY6
[ $? -ne 0 ] && fail=1

echo
if [ $fail -eq 0 ]; then echo "全部通过 ✓"; else echo "有失败项 ✗"; fi
exit $fail
