# 02 下载三个源码仓库（公开仓库，无需任何授权）
. (Join-Path $PSScriptRoot 'common.ps1')

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " 星枢平台 · 下载源码" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

$repos = @(
    @{ Name = 'xs-platform'; Url = 'https://github.com/wcyddaa/xs-platform.git' },
    @{ Name = 'ai-assistant'; Url = 'https://github.com/wcyddaa/ai-assistant.git' },
    @{ Name = 'fastapi-ai-assistant'; Url = 'https://github.com/wcyddaa/fastapi-ai-assistant.git' }
)

New-Item -ItemType Directory -Path $SrcDir -Force | Out-Null

foreach ($repo in $repos) {
    Write-Step "同步 $($repo.Name)"
    $dir = Join-Path $SrcDir $repo.Name
    if (Test-Path (Join-Path $dir '.git')) {
        Write-Info "已存在，执行 git pull ..."
        & git.exe -C $dir -c http.proxy= -c https.proxy= pull --ff-only
        if ($LASTEXITCODE -ne 0) {
            Write-Warn2 "拉取失败，保留现有代码继续（可手动删除 $dir 后重跑本脚本）"
        }
    } else {
        if (Test-Path $dir) { Remove-Item $dir -Recurse -Force }
        & git.exe -c http.proxy= -c https.proxy= clone --depth 1 $repo.Url $dir
        if ($LASTEXITCODE -ne 0) {
            throw "克隆失败：$($repo.Url)。请检查网络或代理（git config --global --unset http.proxy）"
        }
    }
    Write-Ok "$($repo.Name) -> $dir"
}

Write-Host ""
Write-Ok "三个仓库已就绪：$SrcDir"
Write-Info "xs-platform            : Spring Boot 后端（8 个服务）"
Write-Info "ai-assistant           : uni-app + Vue3 前端"
Write-Info "fastapi-ai-assistant   : LangGraph 智能体服务"
