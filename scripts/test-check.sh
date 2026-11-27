#!/usr/bin/env bash
# 检查器自己的变异测试（meta-test）
#
# 为什么要有：check.sh 是手写逻辑，本身从来没被检查过。历史上它退化成
# 「关键词存在性检查」而给出假绿灯（v1.5.4 就是），假绿灯比没有检查更危险——
# 一旦绿灯，就没人会再人工看那三处了。
#
# 做法：把仓库复制到临时目录，每个样本注入一处已知坏改动，跑 check.sh，
#       **期望它报错**。任何样本被放行，说明检查器退化了，本脚本退出 1。
#
# 用法：./scripts/test-check.sh            跑全部
#       ./scripts/test-check.sh --list     只列样本
set -u
cd "$(dirname "$0")/.." || exit 1
SRC=$(pwd)

if [ "${1:-}" = "--list" ]; then
  echo "样本（全部必须让 check.sh 失败）："
  echo "  1 old-literal     往自测节注入旧标准的原文"
  echo "  2 paraphrase      往自测节注入旧标准的另一种说法（二者之一）"
  echo "  3 negation        「旧的四类已废弃，只认原文或命令」"
  echo "  4 drop-elements   标记块里的枚举值被改成随便写"
  echo "  5 wrong-section   标记块里的字段名被改成看着办"
  echo "  6 quiz-leak       往题目文件塞一条答案正文"
  echo "  7 quiz-header     把标题题数改错"
  echo "  8 version         改 VERSION 不同步 CHANGELOG"
  echo "  9 html-sync       改 md 不重新生成 orca-map.html"
  echo "  10 paraphrase-v2  换说法的裁剪（不含黑名单字眼）"
  echo "  11 negation-v2    「四类不必都凑」"
  echo "  12 key-part2      动判据第二部分的要素（原来无样本覆盖）"
  echo "  13 rename-section 小节标题被改名（覆盖未测分支）"
  exit 0
fi

TMP=$(mktemp -d 2>/dev/null || mktemp -d -t testcheck)
trap 'rm -rf "$TMP"' EXIT

pass=0; failn=0
run_case() {
  local name="$1"; shift
  local dir="$TMP/$name"
  cp -r "$SRC/." "$dir" 2>/dev/null || { mkdir -p "$dir"; cp -r "$SRC"/* "$dir"/; }
  rm -rf "$dir/.git"
  ( cd "$dir" && "$@" ) || { echo "  [SKIP] $name 注入脚本失败"; failn=$((failn+1)); return; }
  if ( cd "$dir" && bash scripts/check.sh >/dev/null 2>&1 ); then
    echo "  [BAD ] $name  ← 注入后 check.sh 仍然通过（检查器退化了）"
    failn=$((failn+1))
  else
    echo "  [OK  ] $name  ← 正确报错"
    pass=$((pass+1))
  fi
}

echo "== 变异测试：注入已知坏改动，check.sh 必须全部失败 =="

# 1 旧标准原文
run_case old-literal bash -c '
python - <<PY
p="README.md"; s=open(p,encoding="utf-8").read()
s=s.replace("- 23 题全对 = 可以放心让它派活","- 23 题全对 = 可以放心让它派活\n- 只给结论不算过，要给 CLI 原文。",1)
open(p,"w",encoding="utf-8").write(s)
PY'

# 2 换说法的旧标准（落在检查小节内部）
run_case paraphrase bash -c '
python - <<PY
p="README.md"; s=open(p,encoding="utf-8").read()
s=s.replace("- 23 题全对 = 可以放心让它派活","- 23 题全对 = 可以放心让它派活\n- 补充：只要给出原文或命令，二者之一即可。",1)
open(p,"w",encoding="utf-8").write(s)
PY'

# 3 否定句
run_case negation bash -c '
python - <<PY
p="README.md"; s=open(p,encoding="utf-8").read()
s=s.replace("## 自测","## 自测\n\n旧的四类依据已废弃，只认原文或命令。\n",1)
open(p,"w",encoding="utf-8").write(s)
PY'

# 4 标记块内的要素被削弱
run_case drop-elements python scripts/mutations/drop-elements.py

# 5 标记块内的要素被改成空话
run_case wrong-section python scripts/mutations/wrong-section.py

# 6 题目文件塞答案
run_case quiz-leak bash -c '
python - <<PY
import re
k=open("templates/self-test-key.md",encoding="utf-8").read()
part=re.split(r"^# 第二部分",k,flags=re.M)[0]
a=[re.sub(r"^\d+\.\s*","",l.strip()).replace("**","")
   for l in part.split("\n") if re.match(r"^\d+\.\s",l.strip())][0]
p="docs/QUIZ.md"; q=open(p,encoding="utf-8").read()
open(p,"w",encoding="utf-8").write(q+"\n"+a+"\n")
PY'

# 7 标题题数改错
run_case quiz-header bash -c '
python - <<PY
p="docs/QUIZ.md"; s=open(p,encoding="utf-8").read()
open(p,"w",encoding="utf-8").write(s.replace("23 问","99 问",1))
PY'

# 8 版本不同步
run_case version bash -c 'printf "9.9.9\n" > VERSION'

# 9 md 改了不重新生成
run_case html-sync bash -c 'printf "\n<!-- mutated -->\n" >> docs/orca-map.md'

# 10-13 用独立注入脚本（避免 shell 转义问题）
run_case paraphrase-v2   python scripts/mutations/paraphrase-v2.py
run_case negation-v2     python scripts/mutations/negation-v2.py
run_case key-part2       python scripts/mutations/key-part2.py
run_case rename-section  python scripts/mutations/rename-section.py

echo
echo "通过 $pass / $((pass+failn))"
if [ $failn -ne 0 ]; then echo "有样本被放行 —— 检查器在该类上退化 ✗"; exit 1; fi
echo "检查器的十三类坏改动全部被抓到 ✓"
