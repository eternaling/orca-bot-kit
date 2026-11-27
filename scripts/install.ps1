# 把 orca-bot-kit 装进一个 Orca bot
# 用法：
#   .\scripts\install.ps1 -BotName "my-bot"
#   .\scripts\install.ps1 -BotName "local-bot" -DocsDir "D:\mydocs\orca-map"
# 不传 -BotName 时会列出可选的 bot 目录。

param(
    [string]$BotName,
    [string]$DocsDir = "$HOME\.orca\docs\orca-map"
)

$ErrorActionPreference = "Stop"
$Repo = Split-Path -Parent $PSScriptRoot
$BotsRoot = Join-Path $HOME ".orca\bots"

if (-not $BotName) {
    Write-Host "可用的 bot 目录（在 $BotsRoot 下）：" -ForegroundColor Cyan
    Get-ChildItem -Path $BotsRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object { "  " + $_.Name }
    Write-Host "`n用法： .\scripts\install.ps1 -BotName <名字>" -ForegroundColor Yellow
    exit 1
}

$BotDir = Join-Path $BotsRoot $BotName
if (-not (Test-Path $BotDir)) {
    Write-Error "找不到 bot 目录：$BotDir"
}

Write-Host "== 1/3 事实源与浏览图 -> $DocsDir" -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path $DocsDir | Out-Null
foreach ($f in @("orca-map.md","orca-panorama.html","orca-workflow.html","QUIZ.md")) {
    Copy-Item (Join-Path $Repo "docs\$f") $DocsDir -Force
    Write-Host "   $f"
}
# reviews 作为过程记录一起带上（可选，缺失不影响使用）
if (Test-Path (Join-Path $Repo "docs\reviews")) {
    Copy-Item (Join-Path $Repo "docs\reviews") $DocsDir -Recurse -Force
    Write-Host "   reviews\"
}

Write-Host "== 2/3 技能 -> $BotDir\skills" -ForegroundColor Cyan
foreach ($s in @("orca-map","dispatch-worker")) {
    $dst = Join-Path $BotDir "skills\$s"
    New-Item -ItemType Directory -Force -Path $dst | Out-Null
    Copy-Item (Join-Path $Repo "skills\$s\SKILL.md") $dst -Force
    Write-Host "   skills\$s\SKILL.md"
}

Write-Host "== 3/3 自测判据 -> $BotDir\memory" -ForegroundColor Cyan
$mem = Join-Path $BotDir "memory"
New-Item -ItemType Directory -Force -Path $mem | Out-Null
Copy-Item (Join-Path $Repo "templates\self-test-key.md") $mem -Force
Write-Host "   memory\self-test-key.md"

Write-Host ""
Write-Host "装好了。还差两步（脚本不替你改这些文件）：" -ForegroundColor Yellow
Write-Host "  1) 在 $BotDir\SOUL.md 的「派活与交付」小节加一句："
Write-Host "     结构与口径见 $DocsDir\orca-map.md（唯一事实来源）。派活清单见 skills/dispatch-worker。内容不确定时读 md，不要凭记忆。" -ForegroundColor DarkGray
Write-Host "  2) 跑一遍自测：$DocsDir\QUIZ.md 共 23 题，判据在 $mem\self-test-key.md（先答题再看）"
