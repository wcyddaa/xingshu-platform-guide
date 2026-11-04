# ============================================================
# 星枢平台一键环境 - 公共函数
# 适用：Windows 10/11 x64，PowerShell 5.1+
# 本文件被其他脚本 dot-source 引用，不单独执行
# ============================================================
$ErrorActionPreference = 'Stop'

if (-not $env:XINGSHU_RUNTIME) {
    $env:XINGSHU_RUNTIME = Join-Path $env:USERPROFILE 'XingShuEnv'
}

$Runtime      = $env:XINGSHU_RUNTIME
$GuideRoot    = Split-Path -Parent $PSScriptRoot
$SrcDir       = Join-Path $Runtime 'src'
$LogDir       = Join-Path $Runtime 'logs'
$PidDir       = Join-Path $Runtime 'pids'
$DlDir        = Join-Path $Runtime 'downloads'
$CfgDir       = Join-Path $Runtime 'config'
$DataDir      = Join-Path $Runtime 'data'
$JdkDir       = Join-Path $Runtime 'jdk21'
$MavenDir     = Join-Path $Runtime 'maven'
$NodeDir      = Join-Path $Runtime 'node'
$PythonDir    = Join-Path $Runtime 'python313'
$UvDir        = Join-Path $Runtime 'uv'
$MysqlDir     = Join-Path $Runtime 'mysql'
$RedisDir     = Join-Path $Runtime 'redis'
$EsDir        = Join-Path $Runtime 'elasticsearch'
$MysqlDataDir = Join-Path $DataDir 'mysql'
$RedisDataDir = Join-Path $DataDir 'redis'
$EsDataDir    = Join-Path $DataDir 'elasticsearch'

# Elasticsearch 安全认证（HTTP 明文 + 账号密码，本地开发统一使用）
$EsUser       = 'elastic'
$EsPass       = 'xingshu123'

$RepoXs       = Join-Path $SrcDir 'xs-platform'
$RepoWeb      = Join-Path $SrcDir 'ai-assistant'
$RepoAi       = Join-Path $SrcDir 'fastapi-ai-assistant'

$SpringPorts  = @(8080, 8081, 8082, 8083, 8084, 8085, 8086, 8087)
$AllPorts     = @(3306, 6379, 9200, 8000, 5173) + $SpringPorts

function Write-Step([string]$Message) {
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Ok([string]$Message) {
    Write-Host "  [OK] $Message" -ForegroundColor Green
}

function Write-Info([string]$Message) {
    Write-Host "  [信息] $Message" -ForegroundColor Gray
}

function Write-Warn2([string]$Message) {
    Write-Host "  [注意] $Message" -ForegroundColor Yellow
}

function Write-Fail([string]$Message) {
    Write-Host "  [失败] $Message" -ForegroundColor Red
}

function Initialize-Runtime {
    foreach ($d in @($Runtime, $SrcDir, $LogDir, $PidDir, $DlDir, $CfgDir, $DataDir)) {
        if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
    }
    $envFile = Join-Path $CfgDir 'app.env.ps1'
    if (-not (Test-Path $envFile)) {
        Copy-Item (Join-Path $GuideRoot 'config\app.env.example') $envFile
        Write-Info "已生成配置文件：$envFile（可填入自己的模型 Key）"
    }
}

function Import-AppConfig {
    $envFile = Join-Path $CfgDir 'app.env.ps1'
    if (Test-Path $envFile) { . $envFile }
    if (-not $env:XINGSHU_MYSQL_PORT) { $env:XINGSHU_MYSQL_PORT = '3306' }
}

function Test-Port([int]$Port) {
    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $task = $client.BeginConnect('127.0.0.1', $Port, $null, $null)
        if (-not $task.AsyncWaitHandle.WaitOne(800)) { return $false }
        $client.EndConnect($task)
        return $true
    } catch {
        return $false
    } finally {
        $client.Close()
    }
}

function Wait-Port([int]$Port, [int]$TimeoutSeconds, [string]$Name) {
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        if (Test-Port $Port) { return $true }
        Start-Sleep -Seconds 2
    }
    Write-Fail "$Name 未在 $TimeoutSeconds 秒内监听端口 $Port"
    return $false
}

function Wait-Url([string]$Url, [int]$TimeoutSeconds, [string]$Name) {
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
        try {
            $resp = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 5
            if ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 500) { return $true }
        } catch {
            # 服务尚未就绪，继续等待
        }
        Start-Sleep -Seconds 2
    }
    Write-Fail "$Name 未在 $TimeoutSeconds 秒内响应 $Url"
    return $false
}

function Get-File([string]$Url, [string]$Dest) {
    if (Test-Path $Dest) {
        if ((Get-Item $Dest).Length -gt 1000) {
            Write-Info "已存在，跳过下载：$(Split-Path -Leaf $Dest)"
            return
        }
    }
    Write-Info "下载 $Url"
    & curl.exe -fL --retry 3 --retry-delay 2 -C - -o $Dest $Url
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $Dest) -or (Get-Item $Dest).Length -lt 1000) {
        throw "下载失败：$Url"
    }
}

function Expand-Zip([string]$Zip, [string]$Dest, [string]$InnerName) {
    if (Test-Path $Dest) {
        Write-Info "目录已存在，跳过解压：$Dest"
        return
    }
    $tmp = Join-Path $Runtime ('tmp_extract_' + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    Write-Info "解压 $(Split-Path -Leaf $Zip) ..."
    & tar.exe -xf $Zip -C $tmp
    if ($LASTEXITCODE -ne 0) { throw "解压失败：$Zip" }
    $source = $tmp
    if ($InnerName) { $source = Join-Path $tmp $InnerName }
    if (-not (Test-Path $source)) { throw "压缩包内未找到目录 $InnerName" }
    Move-Item -Path $source -Destination $Dest
    Remove-Item -Path $tmp -Recurse -Force -ErrorAction SilentlyContinue
}

function Enable-Toolchain {
    $env:JAVA_HOME = $JdkDir
    $env:Path = "$JdkDir\bin;$MavenDir\bin;$NodeDir;$MysqlDir\bin;$RedisDir;$UvDir;$env:Path"
    $env:PYTHON = Join-Path $PythonDir 'python.exe'
}

function Test-MySqlReady {
    $client = Join-Path $MysqlDir 'bin\mysql.exe'
    if (-not (Test-Path $client)) { $client = 'mysql.exe' }
    $env:MYSQL_PWD = '1234'
    try {
        $out = & $client '--host=127.0.0.1' "--port=$env:XINGSHU_MYSQL_PORT" '--user=root' -N -e "SELECT 1;" 2>$null
        return ($LASTEXITCODE -eq 0 -and $out -match '1')
    } catch {
        return $false
    }
}

function Test-RedisReady {
    try {
        $out = & (Join-Path $RedisDir 'redis-cli.exe') -h 127.0.0.1 -p 6379 ping 2>$null
        return ($out -match 'PONG')
    } catch {
        return $false
    }
}

function Es-AuthHeader {
    $pair = "${EsUser}:${EsPass}"
    $b64 = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))
    return @{ Authorization = "Basic $b64" }
}

function Test-EsReady {
    try {
        $resp = Invoke-RestMethod -Uri 'http://localhost:9200/_cluster/health' -Headers (Es-AuthHeader) -TimeoutSec 5
        return ($resp.status -in @('green', 'yellow'))
    } catch {
        return $false
    }
}

function Start-IfNotRunning([string]$Exe, [string[]]$Args2, [string]$WorkingDir, [string]$LogFile, [int]$Port, [string]$Name, [int]$TimeoutSeconds) {
    if (Test-Port $Port) {
        Write-Info "$Name 已在端口 $Port 运行，跳过启动"
        return
    }
    Write-Info "启动 $Name ..."
    $startArgs = @{
        FilePath               = $Exe
        ArgumentList           = $Args2
        RedirectStandardOutput = "$LogFile.out.log"
        RedirectStandardError  = "$LogFile.err.log"
        WindowStyle            = 'Hidden'
        PassThru               = $true
    }
    if ($WorkingDir) { $startArgs.WorkingDirectory = $WorkingDir }
    $p = Start-Process @startArgs
    Set-Content -Path (Join-Path $PidDir ("{0}.pid" -f $Name)) -Value $p.Id
    $ok = Wait-Port $Port $TimeoutSeconds $Name
    if (-not $ok) {
        Write-Fail "$Name 启动失败，请查看日志：$LogFile.err.log"
    }
    return $ok
}

function Stop-ByPidFile([string]$Name) {
    $pidFile = Join-Path $PidDir ("{0}.pid" -f $Name)
    if (-not (Test-Path $pidFile)) { return }
    $procId = [int](Get-Content $pidFile -Raw).Trim()
    try {
        & taskkill.exe /T /F /PID $procId 2>$null | Out-Null
        Write-Info "已停止 $Name (PID $procId)"
    } catch {
        Write-Info "$Name (PID $procId) 已不在运行"
    }
    Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
}

function Stop-PortOwner([int]$Port, [string]$Name) {
    $conn = Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($conn) {
        & taskkill.exe /T /F /PID $conn.OwningProcess 2>$null | Out-Null
        Write-Info "已停止占用端口 $Port 的进程（$Name）"
    }
}

Initialize-Runtime
Import-AppConfig
