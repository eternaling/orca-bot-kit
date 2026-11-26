#!/usr/bin/env bash
# Orca 版本漂移监测
#
# 这个仓库的所有判据都是照某个 Orca 版本核出来的。Orca 一升级，某些 CLI 原文可能消失或改写，
# 判据就静默失效了 —— check.sh 查不出来（它只查本仓库自身是否自洽，不查外部 CLI）。
#
# 用法：./scripts/drift.sh            正常跑
#       ./scripts/drift.sh --verbose  把每条命中位置也打出来
#
# 退出码：0 = 无漂移；1 = 发现漂移（有原文消失）；2 = Orca 版本与基准不符（需对账）
set -u
cd "$(dirname "$0")/.." || exit 1

VERBOSE=0
[ "${1:-}" = "--verbose" ] && VERBOSE=1

BASE_FILE="orca-baseline.txt"
[ -f "$BASE_FILE" ] || { echo "缺 $BASE_FILE（里面应写着对账时的 Orca 版本，如 1.4.278）"; exit 1; }
BASELINE=$(tr -d ' \r\n' < "$BASE_FILE")

command -v orca >/dev/null 2>&1 || { echo "找不到 orca 命令"; exit 1; }

CUR=$(orca --version 2>/dev/null | head -1 | tr -d ' \r\n')
echo "Orca 基准版本: $BASELINE"
echo "Orca 当前版本: ${CUR:-未知}"

ver_ok=0
[ "$CUR" = "$BASELINE" ] || ver_ok=1
if [ $ver_ok -ne 0 ]; then
  echo "  ⚠ 版本变了 —— 下面的原文仍全部命中则不必改判据；有消失就必须重核，然后更新 $BASE_FILE 并在 CHANGELOG 记一行"
else
  echo "  ✓ 版本未变"
fi
echo

# 两个事实来源：agent-context（覆盖绝大多数）与 skills get orchestration（少数只在里面）
TMP=$(mktemp -d 2>/dev/null || mktemp -d -t drift)
trap 'rm -rf "$TMP"' EXIT

orca agent-context --json > "$TMP/ac.txt" 2>/dev/null || { echo "orca agent-context --json 失败"; exit 1; }
orca skills get orchestration > "$TMP/sk.txt" 2>/dev/null || : > "$TMP/sk.txt"
cat "$TMP/ac.txt" "$TMP/sk.txt" > "$TMP/haystack.txt"

miss=0; total=0
while IFS= read -r line; do
  line=${line%$'\r'}          # 防止 CRLF 检出带来的 \r 导致必然不命中
  [ -z "$line" ] && continue
  case "$line" in \#*) continue ;; esac
  label=${line%%|*}
  needle=${line#*|}
  total=$((total+1))
  if grep -Fq -- "$needle" "$TMP/haystack.txt"; then
    if [ $VERBOSE -eq 1 ]; then
      where=$(grep -Fl -- "$needle" "$TMP/ac.txt" >/dev/null 2>&1 && echo "agent-context" || echo "skills")
      echo "  ✓ $label  [$where]"
    fi
  else
    miss=$((miss+1))
    echo "  ✗ $label"
    echo "     找不到原文: $needle"
  fi
done < scripts/drift-checks.txt

echo
echo "检查 $total 条，漂移 $miss 条"
if [ $miss -gt 0 ]; then
  echo
  echo "有原文消失 ⇒ 相关判据可能已失效。要做的："
  echo "  1. orca agent-context --json | grep -A6 '<相关命令>'   看新说法"
  echo "  2. 改 docs/orca-map.md（唯一事实源）→ 同步 HTML/QUIZ/README"
  echo "  3. 按 CHANGELOG 的规则决定升 MAJOR / MINOR / PATCH，改 VERSION 与 $BASE_FILE"
  echo "  4. ./scripts/check.sh 与 ./scripts/drift.sh 都要过"
  exit 1
fi
[ $ver_ok -ne 0 ] && exit 2
echo "无漂移 ✓"
exit 0
