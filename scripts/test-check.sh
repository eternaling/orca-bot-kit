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
# 修 #7：Windows/GBK 控制台下 python 打印中文会乱码（显示成 ????），
# 强制 python 用 UTF-8 输出；这比 chcp 65001 干净，不改动用户控制台码页。
export PYTHONIOENCODING=utf-8
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
  echo "  14 weaken-source   削弱数据源后同步（逐字一致不等于正确）"
  echo "  15 dup-block       追加第二个标记块（两个事实源）"
  echo "  16 move-block       标记块挪出指定小节"
  echo "  17 star-residue     HTML 里留 Markdown 星号（并入 #1 后的覆盖）"
  echo "  18 version-bump     VERSION 与 CHANGELOG 首节不一致"
  echo "  19 case-count       README 写的用例数与 run_case 实际数不一致"
  exit 0
fi

TMP=$(mktemp -d 2>/dev/null || mktemp -d -t testcheck)
trap 'rm -rf "$TMP"' EXIT

pass=0; failn=0; gaps=0
run_case() {
  local name="$1"; shift
  local dir="$TMP/$name"
  cp -r "$SRC/." "$dir" 2>/dev/null || { mkdir -p "$dir"; cp -r "$SRC"/* "$dir"/; }
  rm -rf "$dir/.git"
  ( cd "$dir" && "$@" ) || { echo "  [SKIP] $name 注入脚本失败"; failn=$((failn+1)); return; }
  ( cd "$dir" && bash scripts/check.sh > "$TMP/$name.log" 2>&1 )
  local rc=$?
  if [ $rc -eq 0 ]; then
    echo "  [BAD ] $name  ← 注入后 check.sh 仍然通过（检查器退化了）"
    failn=$((failn+1)); return
  fi
  # 必须是因为「报出了错」而失败，不是脚本自己崩了 —— 否则任何无关失败都算「抓住了」
  if grep -qE "FAIL|不一致|不同步|★|失败" "$TMP/$name.log"; then
    echo "  [OK  ] $name  ← 正确报错"
    pass=$((pass+1))
  else
    echo "  [SKIP] $name  ← 退出码非 0 但没有任何报错（脚本崩了？不算抓到）"
    failn=$((failn+1))
  fi
}


# 已知缺口：这几类 check.sh 现在**抓不到**（删掉 6b 黑名单的代价）。
# 保留在套件里，但记为 [GAP] 而不是失败 —— 不让套件假装自己是全绿的。
run_case_gap() {
  local name="$1"; shift
  local dir="$TMP/$name"
  cp -r "$SRC/." "$dir" 2>/dev/null || { mkdir -p "$dir"; cp -r "$SRC"/* "$dir"/; }
  rm -rf "$dir/.git"
  ( cd "$dir" && "$@" ) || { echo "  [SKIP] $name 注入脚本失败"; failn=$((failn+1)); return; }
  ( cd "$dir" && bash scripts/check.sh > "$TMP/$name.log" 2>&1 )
  local rc=$?
  if [ $rc -eq 0 ]; then
    echo "  [GAP ] $name  ← 已知不设防（无此项守护，是预期内的缺口）"
    gaps=$((gaps+1))
  elif grep -qE "FAIL|不一致|不同步|失败" "$TMP/$name.log"; then
    echo "  [NEW ] $name  ← 居然被报错抓住了？检查器比预期强，请改成 run_case"
    pass=$((pass+1))
  else
    echo "  [SKIP] $name  ← 退出码非 0 但无报错（脚本崩了），不算抓到"
    failn=$((failn+1))
  fi
}

echo "== 变异测试：注入已知坏改动，check.sh 必须全部失败 =="

# 1 旧标准原文
run_case_gap old-literal bash -c '
python - <<PY
p="README.md"; s=open(p,encoding="utf-8").read()
s=s.replace("- 23 题全对 = 可以放心让它派活","- 23 题全对 = 可以放心让它派活\n- 只给结论不算过，要给 CLI 原文。",1)
open(p,"w",encoding="utf-8").write(s)
PY'

# 2 换说法的旧标准（落在检查小节内部）
run_case_gap paraphrase bash -c '
python - <<PY
p="README.md"; s=open(p,encoding="utf-8").read()
s=s.replace("- 23 题全对 = 可以放心让它派活","- 23 题全对 = 可以放心让它派活\n- 补充：只要给出原文或命令，二者之一即可。",1)
open(p,"w",encoding="utf-8").write(s)
PY'

# 3 否定句
run_case_gap negation bash -c '
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
run_case_gap paraphrase-v2   python scripts/mutations/paraphrase-v2.py
run_case_gap negation-v2     python scripts/mutations/negation-v2.py
run_case key-part2       python scripts/mutations/key-part2.py
run_case rename-section  python scripts/mutations/rename-section.py

# 14 削弱数据源（删一类）后同步 —— 「逐字一致」不保证正确性
run_case weaken-source python scripts/mutations/weaken-source.py

# 15 追加第二个标记块 —— 两个事实源并存
run_case dup-block python scripts/mutations/dup-block.py

# 16 把标记块挪出指定小节 —— 6a 只看内容、6b 剥掉块后小节为空，都会放过
run_case move-block python scripts/mutations/move-block.py


# 17 星号残留（原 #3 并入 #1 后新覆盖的方向）
run_case star-residue python scripts/mutations/star-residue.py

# 18 版本不同步（原 #4 一直没有样本）
run_case version-bump python scripts/mutations/version-bump.py

# 19 用例数与实际 run_case 数不一致（原 #7 的目标：防止这个数字自己漂）
run_case case-count python scripts/mutations/case-count.py


echo
echo "通过 $pass / $((pass+failn))（另有 $gaps 项为已知缺口）"
if [ $failn -ne 0 ]; then echo "有样本被放行 —— 检查器在该类上退化 ✗"; exit 1; fi
echo "可守的 $pass 类全部抓到 ✓；另有 $gaps 类已知缺口（见 ROADMAP「已知缺口」）"
