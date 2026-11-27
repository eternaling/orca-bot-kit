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

echo "== 6/6 判分标准三处一致（结构约束） =="
python - <<'PY6'
import re,sys

ELEM = {
    '原文片段': r'原文片段|逐字原文|CLI 原文',
    '能跑的命令': r'能跑的命令|能运行的命令|可运行|能验的命令',
    '字段名': r'字段名|参数名',
    '枚举值': r'枚举值',
}
# 裁剪迹象：任何把「依据」压成少数几类的说法。不依赖「依据」这个词，
# 因为这些句子往往只说「原文/命令」，不说「依据」。
CUT2 = (r'原文或命令|原文或者命令|只要原文|只要命令|只认原文|只认命令|两类即可|二选一'
        r'|任选其一即可|不必都认|不用都认|不必都|不用都|仅需原文|仅需命令'
        r'|就行|别的不用|挑着用|不用都凑|给个.{0,6}原文|跑条命令'
        r'|要给 CLI 原文|要给原文|给出 CLI 原文|给出原文')
# 出现下述词则该句谈的是「怎么算过」，不是在裁剪依据 → 豁免
BENIGN = r'不算过|不及格|不达标|必读|见下|见文末'

def section(text, anchor, stop):
    i = text.find(anchor)
    if i < 0: return ''
    j = len(text)
    for s2 in stop:
        k = text.find(s2, i+len(anchor))
        if k >= 0: j = min(j, k)
    return text[i:j]

def logical(seg):
    lines = seg.split('\n'); out=[]; i=0
    while i < len(lines):
        cur = lines[i].strip(); i += 1
        if not cur: continue
        if cur.endswith(('：',':')):
            block=[cur]; blanks=0
            while i < len(lines):
                nxt = lines[i].strip()
                if not nxt:
                    blanks += 1
                    if blanks > 1: i += 1; break
                    i += 1; continue
                blanks = 0
                if re.match(r'^(\d+\.|[-*])\s', nxt) or nxt.endswith('。'):
                    block.append(nxt); i += 1
                    if nxt.endswith('。'): break
                else: break
            out.append(' '.join(block))
        else:
            for part in re.split(r'[。！？]', cur):
                if part.strip(): out.append(part.strip())
    return out

targets = {
    'README 自测节':  (open('README.md',encoding='utf-8').read(), '## 自测', ['## 内容分成','## 版本与迭代']),
    'QUIZ 前言':      (open('docs/QUIZ.md',encoding='utf-8').read(), '# 考 bot', ['## 题']),
    '判据第二部分':    (open('templates/self-test-key.md',encoding='utf-8').read(), '# 第二部分', ['# 第三部分']),
}

bad = []
for name,(text,anchor,stop) in targets.items():
    seg = section(text, anchor, stop)
    if not seg:
        bad.append(f'{name}: 找不到该小节（标题被改名了？）'); continue
    sents = logical(seg)

    # ① 必须至少有一句把四类列全（正例基准）
    if not any(all(re.search(pat, sn) for pat in ELEM.values()) for sn in sents):
        bad.append(f'{name}: 没有任何一句把四类依据列全')

    # ②' 四要素行不得被削弱成「可写可不写」这类空话
    WEAK = r'可写可不写|可选|不一定|可以不给|随便|随意|非必需|可有可无'
    for line in seg.splitlines():
        ln = line.strip()
        if not ln: continue
        if not re.search(r'原文片段|能跑的命令|字段名|枚举值', ln): continue
        if re.search(WEAK, ln):
            bad.append(f'{name}: 四要素里的"{{"}}'"'"'被削弱 → 「{ln[:70]}」'.replace('"{{"}}'"'"'','要素'))
        # 要素行冒号后内容太短 = 没给可核对的东西
        m = re.search(r'[：:]\s*(.*)$', ln)
        if m and len(m.group(1).strip()) < 8:
            bad.append(f'{name}: 四要素某行没给具体说明 → 「{ln[:70]}」')

    # ② 不得有裁剪句：**逐行**查，不在合并块上查
    #    （合并块会同时含有「四类定义」和「裁剪句」，一起判会互相掩护）
    for line in seg.splitlines():
        ln = line.strip()
        if not ln: continue
        benign_ok = bool(re.search(BENIGN, ln)) and not re.search(r'原文|命令', ln)
        if re.search(CUT2, ln) and not benign_ok:
            if all(re.search(pat, ln) for pat in ELEM.values()):
                continue   # 这一行自己把四类列全了，是正常写法
            # 只是提到「四类」而没有重新定义要素（如「四类依据任选其一即可」）→ 视为描述既有四类
            if re.search(r'四类', ln) and not re.search(r'原文或命令|只要原文|只认原文|只认命令|两类即可|不必都|不用都|挑着用|不用都凑', ln):
                continue
            bad.append(f'{name}: 出现裁剪四类的句子 → 「{ln[:70]}」')

if bad:
    for b in bad: print('  [FAIL]', b)
    print('  -> 失败'); sys.exit(1)
print('  三处：均有列全四类的句子，且无裁剪句 -> OK')
print('  注：结构检查，不做语义判断；改判分标准后仍需人看一遍 diff。')
sys.exit(0)
PY6
[ $? -ne 0 ] && fail=1

echo
if [ $fail -eq 0 ]; then echo "全部通过 ✓"; else echo "有失败项 ✗"; fi
exit $fail
