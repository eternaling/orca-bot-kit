#!/usr/bin/env python3
"""把 standards/grading.md 的正文同步进那三处带标记的位置。

为什么要有这个脚本：判分标准以前是三段手写散文，只能用词法去猜「三处是否一致」，
结果一直在「漏检」和「误报」之间挪。现在改成：

  standards/grading.md        ← 唯一事实源（数据）
  三处标记之间的内容           ← 由本脚本写入，逐字等于上面那份
  check.sh                    ← 只做逐字比对，不猜语义

用法：
  python scripts/apply-grading.py      # 同步（幂等）
  python scripts/apply-grading.py --check   # 只比对，不一致退出 1（check.sh 用）

标记：
  <!-- grading:begin --> ... <!-- grading:end -->
"""
import sys, pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "standards" / "grading.md"
BEGIN = "<!-- grading:begin · 本块由 standards/grading.md 生成，勿手改；要改先改数据源再跑 scripts/apply-grading.py -->"
END = "<!-- grading:end · 以上由 scripts/apply-grading.py 写入 -->"
TARGETS = ["README.md", "docs/QUIZ.md", "templates/self-test-key.md"]


def canonical() -> str:
    return SRC.read_text(encoding="utf-8").strip("\n")


def extract(text: str):
    """返回标记之间的内容；没有标记返回 None"""
    i = text.find(BEGIN)
    j = text.find(END)
    if i < 0 or j < 0 or j < i:
        return None
    return text[i + len(BEGIN):j].strip("\n")


def main() -> int:
    check_only = "--check" in sys.argv
    want = canonical()
    problems = []

    for rel in TARGETS:
        p = ROOT / rel
        text = p.read_text(encoding="utf-8")
        got = extract(text)
        if got is None:
            problems.append(f"{rel}: 找不到 grading 标记")
            continue
        if got.strip("\n") == want:
            continue
        if check_only:
            problems.append(f"{rel}: 标记之间的内容与 standards/grading.md 不一致")
            continue
        new = text[: text.find(BEGIN)] + BEGIN + "\n" + want + "\n" + text[text.find(END):]
        p.write_text(new, encoding="utf-8")
        print(f"  已同步 {rel}")

    if problems:
        for x in problems:
            print("  [FAIL]", x)
        print("  -> 失败：跑 python scripts/apply-grading.py 同步，或改 standards/grading.md")
        return 1
    if check_only:
        print("  三处判分标准与 standards/grading.md 逐字一致 -> OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
