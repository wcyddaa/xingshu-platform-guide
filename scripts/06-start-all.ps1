# 06 启动全部服务（8 个后端 + FastAPI + 前端）
. (Join-Path $PSScriptRoot 'common.ps1')

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " 星枢平台 · 启动全部服务" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

Enable-Toolchain

function Start-InfraIfNeeded {
    if (-not (Test-Port ([int]$env:XINGSHU_MYSQL_PORT))) {
        if (Test-Path (Join-Path $MysqlDir 'bin\mysqld.exe')) {
            Write-Info "启动 MySQL ..."
            Start-Process -FilePath (Join-Path $MysqlDir 'bin\mysqld.exe') -ArgumentList @(
                "--basedir=`"$MysqlDir`"", "--datadir=`"$MysqlDataDir`"",
                "--port=$($env:XINGSHU_MYSQL_PORT)", "--character-set-server=utf8mb4",
                "--collation-server=utf8mb4_0900_ai_ci",
                "--log-error=`"$(Join-Path $LogDir 'mysql.err.log')`""
            ) -WindowStyle Hidden | Out-Null
            if (-not (Wait-Port ([int]$env:XINGSHU_MYSQL_PORT) 90 'MySQL')) { throw "MySQL 启动失败" }
        } else {
            throw "MySQL 未启动，请先执行 01-install-infra.ps1"
        }
    }
    if (-not (Test-Port 6379)) {
        $conf = Join-Path $CfgDir 'redis.conf'
        if (-not (Test-Path $conf)) { throw "缺少 Redis 配置，请先执行 01-install-infra.ps1" }
        Start-Process -FilePath (Join-Path $RedisDir 'redis-server.exe') -ArgumentList "`"$conf`"" -WorkingDirectory $RedisDir -WindowStyle Hidden -RedirectStandardOutput (Join-Path $LogDir 'redis.out.log') -RedirectStandardError (Join-Path $LogDir 'redis.err.log') | Out-Null
        if (-not (Wait-Port 6379 30 'Redis')) { throw "Redis 启动失败" }
    }
    if (-not (Test-EsReady)) {
        if (Test-Path (Join-Path $EsDir 'bin\elasticsearch.bat')) {
            Write-Info "启动 Elasticsearch（约 1 分钟）..."
            Start-Process -FilePath 'cmd.exe' -ArgumentList "/c `"$(Join-Path $EsDir 'bin\elasticsearch.bat')`"" -RedirectStandardOutput (Join-Path $LogDir 'es.out.log') -RedirectStandardError (Join-Path $LogDir 'es.err.log') -WindowStyle Hidden | Out-Null
            if (-not (Wait-Url 'http://localhost:9200/_cluster/health' 300 'Elasticsearch')) { throw "Elasticsearch 启动失败" }
        } else {
            throw "Elasticsearch 未启动，请先执行 01-install-infra.ps1"
        }
    }
}

function Start-Backend([string]$Name, [string]$Module, [int]$Port, [string]$WorkDir, [string[]]$ExtraArgs) {
    if (Test-Port $Port) {
        Write-Info "$Name 已在端口 $Port 运行，跳过"
        return
    }
    $jar = Join-Path $RepoXs "$Module\target\$Module-1.0.0.jar"
    if (-not (Test-Path $jar)) { throw "缺少 $jar，请先执行 05-build.ps1" }
    $args2 = @('-Xms256m', '-Xmx1024m', '-Dfile.encoding=UTF-8', '-jar', "`"$jar`"") + $ExtraArgs
    $p = Start-Process -FilePath (Join-Path $JdkDir 'bin\java.exe') -ArgumentList $args2 -WorkingDirectory $WorkDir `
        -RedirectStandardOutput (Join-Path $LogDir "$Name.out.log") `
        -RedirectStandardError (Join-Path $LogDir "$Name.err.log") -WindowStyle Hidden -PassThru
    Set-Content -Path (Join-Path $PidDir "$Name.pid") -Value $p.Id
    Write-Info "等待 $Name (:$Port) 启动 ..."
    if (-not (Wait-Port $Port 180 $Name)) {
        Write-Info "查看日志：$LogDir\$Name.err.log"
        throw "$Name 启动失败"
    }
    Write-Ok "$Name 已启动：http://localhost:$Port"
}

Write-Step "1/3 确认基础设施"
Start-InfraIfNeeded
Write-Ok "MySQL / Redis / Elasticsearch 均已就绪"

Write-Step "2/3 启动 Spring Boot 服务（8080-8087）"
New-Item -ItemType Directory -Path (Join-Path $RepoXs 'uploads') -Force | Out-Null
$env:XINGSHU_ES_URI = 'http://localhost:9200'
$env:XINGSHU_ES_USERNAME = ''
$env:XINGSHU_ES_PASSWORD = ''

Start-Backend 'xs-auth'   'xs-auth'   8081 $RepoXs @()
Start-Backend 'xs-user'   'xs-user'   8080 $RepoXs @()
Start-Backend 'xs-course' 'xs-course' 8082 $RepoXs @()
Start-Backend 'xs-config' 'xs-config' 8086 $RepoXs @()
Start-Backend 'xs-data'   'xs-data'   8085 $RepoXs @()
Start-Backend 'xs-book'   'xs-book'   8083 $RepoXs @('--spring.elasticsearch.uris=http://localhost:9200', '--spring.elasticsearch.username=', '--spring.elasticsearch.password=')
Start-Backend 'xs-exam'   'xs-exam'   8084 $RepoXs @()
Start-Backend 'xs-learning' 'xs-learning' 8087 $RepoXs @()

Write-Step "3/3 启动 FastAPI 与前端"
if (-not (Test-Port 8000)) {
    $uvicorn = Join-Path $RepoAi '.venv\Scripts\uvicorn.exe'
    if (-not (Test-Path $uvicorn)) { throw "Python 环境未就绪，请先执行 05-build.ps1" }
    Start-Process -FilePath $uvicorn -ArgumentList @('main:app', '--host', '0.0.0.0', '--port', '8000') -WorkingDirectory $RepoAi `
        -RedirectStandardOutput (Join-Path $LogDir 'fastapi.out.log') -RedirectStandardError (Join-Path $LogDir 'fastapi.err.log') -WindowStyle Hidden -PassThru |
        ForEach-Object { Set-Content -Path (Join-Path $PidDir 'fastapi.pid') -Value $_.Id }
    if (-not (Wait-Port 8000 120 'FastAPI')) { throw "FastAPI 启动失败" }
}
Write-Ok "FastAPI 已启动：http://localhost:8000"

if (-not (Test-Port 5173)) {
    $env:npm_config_registry = 'https://registry.npmmirror.com'
    $p = Start-Process -FilePath 'cmd.exe' -ArgumentList @('/c', 'npm run dev:h5') -WorkingDirectory $RepoWeb `
        -RedirectStandardOutput (Join-Path $LogDir 'web.out.log') -RedirectStandardError (Join-Path $LogDir 'web.err.log') -WindowStyle Hidden -PassThru
    Set-Content -Path (Join-Path $PidDir 'web.pid') -Value $p.Id
    if (-not (Wait-Port 5173 180 '前端')) { throw "前端启动失败，详见 $LogDir\web.err.log" }
}
Write-Ok "前端已启动：http://localhost:5173"

Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host " 全部服务已启动" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host " 前端入口   : http://localhost:5173"
Write-Host " 认证服务   : http://localhost:8081"
Write-Host " 智能体服务 : http://localhost:8000/docs"
Write-Host ""
Write-Host " 初始账号（仅此一个，密码 123456）："
Write-Host "   管理员 admin001 | 其余教师/学生账号请登录后在前端「用户管理」创建"
Write-Host ""
Write-Host " 下一步：.\scripts\verify.ps1 一键验证"
