# 07 停止全部服务（默认保留 MySQL/Redis/ES，可加 -IncludeInfra）
param(
    [switch]$IncludeInfra
)
. (Join-Path $PSScriptRoot 'common.ps1')

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " 星枢平台 · 停止服务" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

$services = @('web', 'fastapi', 'xs-learning', 'xs-exam', 'xs-book', 'xs-data',
              'xs-config', 'xs-course', 'xs-user', 'xs-auth')
foreach ($name in $services) {
    Stop-ByPidFile $name
}

# 兜底：按端口清理残留进程（防止 pid 文件丢失）
foreach ($port in @(5173, 8000, 8087, 8084, 8083, 8085, 8086, 8082, 8080, 8081)) {
    Stop-PortOwner $port "端口$port"
}

if ($IncludeInfra) {
    Write-Step "停止基础设施"
    Stop-PortOwner 9200 'Elasticsearch'
    if (Test-Path (Join-Path $RedisDir 'redis-cli.exe')) {
        & (Join-Path $RedisDir 'redis-cli.exe') -h 127.0.0.1 -p 6379 shutdown 2>$null | Out-Null
    }
    Stop-PortOwner 6379 'Redis'
    if (Test-Path (Join-Path $MysqlDir 'bin\mysqladmin.exe')) {
        $env:MYSQL_PWD = '1234'
        & (Join-Path $MysqlDir 'bin\mysqladmin.exe') '--host=127.0.0.1' "--port=$env:XINGSHU_MYSQL_PORT" '--user=root' shutdown 2>$null | Out-Null
    }
    Stop-PortOwner ([int]$env:XINGSHU_MYSQL_PORT) 'MySQL'
} else {
    Write-Info "MySQL / Redis / Elasticsearch 保持运行（如需一并停止，执行 07-stop-all.ps1 -IncludeInfra）"
}

Write-Host ""
Write-Ok "已停止"
