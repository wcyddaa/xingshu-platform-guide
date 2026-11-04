# 00 环境自检：确认系统、磁盘、Git、端口可用
. (Join-Path $PSScriptRoot 'common.ps1')

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " 星枢平台 · 环境自检" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

Write-Step "1/5 检查操作系统"
if (-not [Environment]::Is64BitOperatingSystem) {
    throw "需要 64 位 Windows（当前为 32 位系统）"
}
$os = (Get-CimInstance Win32_OperatingSystem).Caption
Write-Ok "系统：$os"

Write-Step "2/5 检查 PowerShell 与解压工具"
if ($PSVersionTable.PSVersion.Major -lt 5) {
    throw "需要 PowerShell 5.1 及以上版本"
}
Write-Ok "PowerShell $($PSVersionTable.PSVersion)"
if (-not (Get-Command tar.exe -ErrorAction SilentlyContinue)) {
    throw "未找到 tar.exe（Windows 10 1803+ 自带，请在命令行执行 tar --version 检查）"
}
Write-Ok "tar.exe 可用"

Write-Step "3/5 检查 Git"
$git = Get-Command git.exe -ErrorAction SilentlyContinue
if (-not $git) {
    Write-Fail "未安装 Git for Windows"
    Write-Info "下载地址：https://git-scm.com/download/win（安装后重新打开 PowerShell）"
    throw "缺少 Git"
}
Write-Ok "Git：$((& git.exe --version) -join '')"

Write-Step "4/5 检查磁盘空间"
$letter = (Split-Path -Qualifier $Runtime).TrimEnd(':')
$drive = Get-PSDrive -Name $letter
$freeGb = [math]::Round($drive.Free / 1GB, 1)
if ($freeGb -lt 10) {
    Write-Fail "磁盘剩余 $freeGb GB，至少需要 10 GB（ES 数据 + Maven 依赖 + Node 依赖）"
} else {
    Write-Ok "运行目录所在磁盘剩余 $freeGb GB"
}
Write-Info "运行目录：$Runtime"

Write-Step "5/5 检查端口"
$busy = @()
foreach ($port in $AllPorts) {
    if (Test-Port $port) { $busy += $port }
}
if ($busy.Count -eq 0) {
    Write-Ok "所有端口空闲：$($AllPorts -join ', ')"
} else {
    Write-Warn2 "以下端口已被占用：$($busy -join ', ')"
    Write-Info "如果占用者是本平台已启动的服务，可直接运行 .\scripts\07-stop-all.ps1 先停止；"
    Write-Info "如果是你本机已有的 MySQL/Redis/ES，脚本会复用并跳过安装（MySQL 需 root/1234）。"
}

Write-Host ""
Write-Ok "环境自检完成，可继续执行 01-install-infra.ps1"
