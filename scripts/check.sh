#!/usr/bin/env bash
# 机械检查：两份 HTML 的结构 + QUIZ 数量自洽 + Markdown 星号残留
# 用法：在仓库根目录跑 ./scripts/check.sh   退出码 0 = 全过
set -u
# 修 #7：Windows/GBK 控制台下 python 打印中文会乱码（显示成 ????），
# 强制 python 用 UTF-8 输出；这比 chcp 65001 干净，不改动用户控制台码页。
export PYTHONIOENCODING=utf-8
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
  # 星号残留并入本项（原 #3）：HTML 里出现 ** 会被当文字显示
  if grep -n '\*\*[^*<]\{1,25\}\*\*' "$f" >/dev/null 2>&1; then
    echo "  [FAIL] $f 里有 ** 残留（会被当文字渲染）"; fail=1
  fi
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

# 泄漏比对要排除 grading 标记块：那里面是判分标准的示例原文，不是某道题的答案
_B="<!-- grading:begin · 本块由 standards/grading.md 生成，勿手改；要改先改数据源再跑 scripts/apply-grading.py -->"; _E="<!-- grading:end · 以上由 scripts/apply-grading.py 写入 -->"
_q=re.sub(re.escape(_B)+r'.*?'+re.escape(_E), '', q, flags=re.S)

# 泄漏检测（三道，每道都能单独抓到一类）
# ① 标题级：题目文件不得出现「答案/判据/参考/解答」类小标题
head_leak = re.findall(r'^#{1,6}\s*.*(?:答案|判据|参考|解答|key|answer)', _q, re.M | re.I)

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
        if len(w) >= 24 and w in _q:
            win_hits.append(w)
            break

# ③ 相似度兜底：题目文件里任意 200 字段落，与某条答案去标点后的相似度 > 0.85 也算泄漏
def norm(t):
    return re.sub(r'[\s\W_]+', '', t)
qn = norm(_q)
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

echo "== 3/6 版本一致性 =="
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

echo "== 4/6 生成物与示意图 =="
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

echo "== 5/6 判分标准三处一致（逐字比对数据源） =="
if command -v python >/dev/null 2>&1; then
  # 6a-0 数据源自检：四类必须都在。没有这一条，「逐字一致」只保证同步、不保证正确性
  python - <<'PYD'
import sys
s=open('standards/grading.md',encoding='utf-8').read()
need={'原文片段':'原文片段|逐字原文','能跑的命令':'能跑的命令|能运行的命令','字段名':'字段名|参数名','枚举值':'枚举值'}
miss=[k for k in need if k not in s]
if miss:
    print('  [FAIL] standards/grading.md 缺四类中的:', miss, '（数据源被削弱了）')
    sys.exit(1)
print('  数据源四类齐全 -> OK')
PYD
  [ $? -ne 0 ] && fail=1

  # 6a 三处标记块必须逐字等于数据源
  python scripts/apply-grading.py --check
  [ $? -ne 0 ] && fail=1

  # 6a-2 结构断言：标记必须各恰好一次，且块必须落在指定小节内
  python - <<'PYE'
import sys
B="<!-- grading:begin · 本块由 standards/grading.md 生成，勿手改；要改先改数据源再跑 scripts/apply-grading.py -->"; E="<!-- grading:end · 以上由 scripts/apply-grading.py 写入 -->"
# 每个文件里，块必须落在哪个小节区间
SPEC={
 'README.md': ('## 自测', ['## 内容分成','## 版本与迭代']),
 'docs/QUIZ.md': ('# 考 bot', ['## 题']),
 'templates/self-test-key.md': ('# 第二部分', ['# 第三部分']),
}
bad=[]
for f,(anchor,stops) in SPEC.items():
    t=open(f,encoding='utf-8').read()
    nb, ne = t.count(B), t.count(E)
    if nb!=1 or ne!=1:
        bad.append(f'{f}: 标记不成对/重复（begin={nb}, end={ne}）'); continue
    i=t.find(anchor)
    if i<0:
        bad.append(f'{f}: 找不到小节标题「{anchor}」'); continue
    j=len(t)
    for st in stops:
        k=t.find(st, i+len(anchor))
        if k>=0: j=min(j,k)
    if not (i < t.find(B) < t.find(E) < j):
        bad.append(f'{f}: 标记块不在「{anchor}」小节内')
if bad:
    for b in bad: print('  [FAIL]', b)
    sys.exit(1)
print('  三处标记各 1 对且都在指定小节内 -> OK')
PYE
  [ $? -ne 0 ] && fail=1
else
  echo "  [WARN] 没有 python：6a 这一项没验（不是通过）"
fi
echo "== 6/6 变异用例数 =="
if command -v python >/dev/null 2>&1; then
python - <<'PY7'
import re,sys
t=open('scripts/test-check.sh',encoding='utf-8').read()
actual=len([l for l in t.splitlines() if l.startswith('run_case ') or l.startswith('run_case_gap ')])
r=open('README.md',encoding='utf-8').read()
nums=set()
for m in re.finditer(r'(\d+)\s*个(?:坏样本|用例)', r):
    nums.add(int(m.group(1)))
bad=[n for n in nums if n!=actual]
if bad:
    print(f'  [FAIL] README 写的用例数 {sorted(nums)} 与实际 run_case={actual} 不一致')
    sys.exit(1)
if not nums:
    print('  [FAIL] README 里找不到「N 个用例/坏样本」的说法'); sys.exit(1)
print(f'  用例数一致：{actual} -> OK')
sys.exit(0)
PY7
[ $? -ne 0 ] && fail=1
else
  echo "  [WARN] 没有 python：这一项没验（不是通过）"
fi

echo
if [ $fail -eq 0 ]; then echo "全部通过 ✓"; else echo "有失败项 ✗"; fi
exit $fail
