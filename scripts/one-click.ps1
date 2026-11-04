# 一键执行：环境自检 -> 安装基础设施 -> 下载源码 -> 初始化数据库/ES -> 编译 -> 启动 -> 验证
$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "########################################################" -ForegroundColor Magenta
Write-Host "#  星枢平台 · 一键本地部署（无需 Docker / 无需 Mock）" -ForegroundColor Magenta
Write-Host "#  预计首次执行需要下载约 1.3 GB，请保持网络畅通" -ForegroundColor Magenta
Write-Host "########################################################" -ForegroundColor Magenta

$started = Get-Date
try {
    & (Join-Path $PSScriptRoot '00-check-env.ps1')
    & (Join-Path $PSScriptRoot '01-install-infra.ps1')
    & (Join-Path $PSScriptRoot '02-clone-repos.ps1')
    & (Join-Path $PSScriptRoot '03-init-db.ps1')
    & (Join-Path $PSScriptRoot '04-init-es.ps1')
    & (Join-Path $PSScriptRoot '05-build.ps1')
    & (Join-Path $PSScriptRoot '06-start-all.ps1')
    & (Join-Path $PSScriptRoot 'verify.ps1')
} catch {
    Write-Host ""
    Write-Fail $_.Exception.Message
    Write-Host "  可重新执行本脚本（已完成的步骤会自动跳过），或按 README 的「分步执行」排查。" -ForegroundColor Yellow
    exit 1
}

$elapsed = [math]::Round(((Get-Date) - $started).TotalMinutes, 1)
Write-Host ""
Write-Host "全部完成，用时约 $elapsed 分钟。" -ForegroundColor Green
Write-Host "浏览器访问 http://localhost:5173 开始演示。" -ForegroundColor Green
