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
  echo "  4 drop-elements   把自测节的四要素删成一句话"
  echo "  5 wrong-section   把四要素从自测节搬到别处"
  echo "  6 quiz-leak       往题目文件塞一条答案正文"
  echo "  7 quiz-header     把标题题数改错"
  echo "  8 version         改 VERSION 不同步 CHANGELOG"
  echo "  9 html-sync       改 md 不重新生成 orca-map.html"
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

# 4 删掉四要素
run_case drop-elements bash -c '
python - <<PY
p="README.md"; s=open(p,encoding="utf-8").read()
s=s.replace("四类任一即可：逐字原文片段 / 能跑的命令 / 字段名或参数名 / 完整枚举值","结论要对")
open(p,"w",encoding="utf-8").write(s)
PY'

# 5 把四要素搬到别处（自测节内不再有）
run_case wrong-section bash -c '
python - <<PY
p="README.md"; s=open(p,encoding="utf-8").read()
line="四类任一即可：逐字原文片段 / 能跑的命令 / 字段名或参数名 / 完整枚举值"
s=s.replace(line,"结论要对",1)
s=s.rstrip()+"\n\n四类任一即可：逐字原文片段 / 能跑的命令 / 字段名或参数名 / 完整枚举值\n"
open(p,"w",encoding="utf-8").write(s)
PY'

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

echo
echo "通过 $pass / $((pass+failn))"
if [ $failn -ne 0 ]; then echo "有样本被放行 —— 检查器在该类上退化 ✗"; exit 1; fi
echo "检查器的九类坏改动全部被抓到 ✓"
