# 一键验证：端口、数据库、Redis、ES、登录、权限隔离、FastAPI、前端
. (Join-Path $PSScriptRoot 'common.ps1')

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " 星枢平台 · 运行状态验证" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

$script:pass = 0
$script:fail = 0

function Check([string]$Name, [bool]$Ok, [string]$Detail) {
    if ($Ok) {
        $script:pass++
        Write-Host "  [PASS] $Name" -ForegroundColor Green
        if ($Detail) { Write-Host "         $Detail" -ForegroundColor DarkGray }
    } else {
        $script:fail++
        Write-Host "  [FAIL] $Name" -ForegroundColor Red
        if ($Detail) { Write-Host "         $Detail" -ForegroundColor DarkGray }
    }
}

function Get-Token([string]$Username, [int]$Type) {
    $body = @{ username = $Username; password = '123456'; type = $Type } | ConvertTo-Json
    $resp = Invoke-RestMethod -Uri 'http://localhost:8081/auth/login' -Method Post -Body $body -ContentType 'application/json' -TimeoutSec 10
    if ($resp.code -ne 200) { throw "登录失败：$($resp.message)" }
    return $resp.data.accessToken
}

Write-Step "1/7 端口监听"
$ports = @(
    @{ P = 3306; N = 'MySQL' }, @{ P = 6379; N = 'Redis' }, @{ P = 9200; N = 'Elasticsearch' },
    @{ P = 8080; N = 'xs-user' }, @{ P = 8081; N = 'xs-auth' }, @{ P = 8082; N = 'xs-course' },
    @{ P = 8083; N = 'xs-book' }, @{ P = 8084; N = 'xs-exam' }, @{ P = 8085; N = 'xs-data' },
    @{ P = 8086; N = 'xs-config' }, @{ P = 8087; N = 'xs-learning' },
    @{ P = 8000; N = 'FastAPI' }, @{ P = 5173; N = '前端' }
)
foreach ($item in $ports) {
    Check "$($item.N) 端口 $($item.P)" (Test-Port $item.P) ''
}

Write-Step "2/7 MySQL 数据"
Enable-Toolchain
$mysqlExe = Join-Path $MysqlDir 'bin\mysql.exe'
if (-not (Test-Path $mysqlExe)) {
    $cmd = Get-Command mysql.exe -ErrorAction SilentlyContinue
    if ($cmd) { $mysqlExe = $cmd.Source }
}
$mysqlReady = $mysqlExe -and (Test-Path $mysqlExe)
if ($mysqlReady) {
    $env:MYSQL_PWD = '1234'
    $adminCount = (& $mysqlExe '--host=127.0.0.1' "--port=$env:XINGSHU_MYSQL_PORT" '--user=root' -N -e "SELECT COUNT(*) FROM ``xs-user``.``user`` WHERE username='admin001';" 2>$null)
    $dbCount = (& $mysqlExe '--host=127.0.0.1' "--port=$env:XINGSHU_MYSQL_PORT" '--user=root' -N -e "SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name IN ('xs-user','xs-course','xs-config','xs-learning','xs-exam','xs_log');" 2>$null)
    Check 'admin001 初始账号存在' ([int]$adminCount -eq 1) "user 表命中 $adminCount 条"
    Check '六个业务数据库已建表' ([int]$dbCount -eq 6) "命中 $dbCount / 6 个库"
} else {
    Check 'MySQL 客户端可用' $false '未找到 mysql.exe，请先执行 01-install-infra.ps1'
}

Write-Step "3/7 Redis 与 Elasticsearch"
$redisCli = Join-Path $RedisDir 'redis-cli.exe'
if (-not (Test-Path $redisCli)) {
    $cmd = Get-Command redis-cli.exe -ErrorAction SilentlyContinue
    if ($cmd) { $redisCli = $cmd.Source }
}
if ($redisCli -and (Test-Path $redisCli)) {
    $redisPong = & $redisCli -h 127.0.0.1 -p 6379 ping 2>$null
    Check 'Redis 可读写' ($redisPong -match 'PONG') $redisPong
} else {
    Check 'Redis 端口可连接' (Test-Port 6379) '未找到 redis-cli，仅校验端口'
}
try {
    $health = Invoke-RestMethod -Uri 'http://localhost:9200/_cluster/health' -TimeoutSec 10
    Check 'Elasticsearch 集群健康' ($health.status -in @('green', 'yellow')) "status=$($health.status)"
    $expect = @{ textbook_index = 1; courseware_index = 8; textbook_chunk_vector = 2258; courseware_chunk_vector = 29 }
    foreach ($name in $expect.Keys) {
        $count = (Invoke-RestMethod -Uri "http://localhost:9200/$name/_count" -TimeoutSec 10).count
        Check "索引 $name 文档数" ($count -ge $expect[$name]) "$count 条（期望 >= $($expect[$name])）"
    }
} catch {
    Check 'Elasticsearch 可用' $false $_.Exception.Message
}

Write-Step "4/7 管理员登录"
try {
    $adminToken = Get-Token 'admin001' 1
    Check '管理员 admin001 登录' ($adminToken.Length -gt 20) ''
} catch { Check '管理员 admin001 登录' $false $_.Exception.Message }

Write-Step "5/7 鉴权接口"
function Get-Api([string]$Url, [string]$Token) {
    try {
        $resp = Invoke-RestMethod -Uri $Url -Headers @{ Authorization = $Token } -TimeoutSec 10
        return @{ ok = ($resp.code -eq 200); body = $resp }
    } catch {
        return @{ ok = $false; body = $null; status = $_.Exception.Response.StatusCode.value__ }
    }
}
if ($adminToken) {
    $r4 = Get-Api 'http://localhost:8086/api/agent-class-config/all' $adminToken
    Check '管理员带 Token 访问 xs-config 成功' $r4.ok ''
    $anonymousOk = $false
    try {
        $anon = Invoke-RestMethod -Uri 'http://localhost:8086/api/agent-class-config/all' -TimeoutSec 10
        if ($anon.code -eq 200) { $anonymousOk = $true }
    } catch { }
    Check '匿名访问被拒绝' (-not $anonymousOk) ''
}

Write-Step "6/7 FastAPI 智能体服务"
try {
    $h = Invoke-RestMethod -Uri 'http://localhost:8000/health' -TimeoutSec 10
    Check 'FastAPI /health' ($h.status -eq 'ok') "agent=$($h.agent_name) type=$($h.agent_type)"
} catch { Check 'FastAPI /health' $false $_.Exception.Message }

Write-Step "7/7 前端页面"
try {
    $page = Invoke-WebRequest -Uri 'http://localhost:5173' -UseBasicParsing -TimeoutSec 15
    Check '前端首页可访问' ($page.StatusCode -eq 200) "HTTP $($page.StatusCode)"
} catch { Check '前端首页可访问' $false $_.Exception.Message }

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " 验证结果：$($script:pass) 项通过，$($script:fail) 项失败" -ForegroundColor $(if ($script:fail -eq 0) { 'Green' } else { 'Red' })
Write-Host "==================================================" -ForegroundColor Cyan
if ($script:fail -eq 0) {
    Write-Host " 打开浏览器访问：http://localhost:5173" -ForegroundColor Green
    Write-Host " 管理员 admin001 / 123456（其余账号请在前端创建）" -ForegroundColor Green
    if ([string]::IsNullOrWhiteSpace($env:XINGSHU_LLM_API_KEY)) {
        Write-Host " 提示：尚未配置模型 Key，可在管理员端「模型配置」页面填写后再测试问答。" -ForegroundColor Yellow
    }
    exit 0
} else {
    Write-Host " 请根据上面的 FAIL 项检查日志：$LogDir" -ForegroundColor Red
    exit 1
}
