# 01 安装并启动基础设施：JDK21 / Maven / Node22 / Python3.13 / uv / MySQL9.6 / Redis3 / ES8.18
. (Join-Path $PSScriptRoot 'common.ps1')

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " 星枢平台 · 安装基础设施（无需 Docker）" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Info "安装目录：$Runtime"

# ---------------- JDK 21 ----------------
Write-Step "1/8 安装 JDK 21"
if (-not (Test-Path (Join-Path $JdkDir 'bin\java.exe'))) {
    $zip = Join-Path $DlDir 'OpenJDK21U-jdk_x64_windows_hotspot_21.0.13_9.zip'
    $url = 'https://mirrors.tuna.tsinghua.edu.cn/Adoptium/21/jdk/x64/windows/OpenJDK21U-jdk_x64_windows_hotspot_21.0.13_9.zip'
    try {
        Get-File $url $zip
    } catch {
        Write-Warn2 "清华镜像失败，改用 Adoptium 官方接口"
        Get-File 'https://api.adoptium.net/v3/binary/latest/21/ga/windows/x64/jdk/hotspot/normal/eclipse' $zip
    }
    Expand-Zip $zip $JdkDir 'jdk-21.0.13+9'
}
Write-Ok "JDK：$JdkDir"

# ---------------- Maven ----------------
Write-Step "2/8 安装 Maven 3.9.9"
if (-not (Test-Path (Join-Path $MavenDir 'bin\mvn.cmd'))) {
    $zip = Join-Path $DlDir 'apache-maven-3.9.9-bin.zip'
    Get-File 'https://archive.apache.org/dist/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.zip' $zip
    Expand-Zip $zip $MavenDir 'apache-maven-3.9.9'
}
Write-Ok "Maven：$MavenDir"

# ---------------- Node ----------------
Write-Step "3/8 安装 Node.js 22"
if (-not (Test-Path (Join-Path $NodeDir 'node.exe'))) {
    $zip = Join-Path $DlDir 'node-v22.14.0-win-x64.zip'
    Get-File 'https://npmmirror.com/mirrors/node/v22.14.0/node-v22.14.0-win-x64.zip' $zip
    Expand-Zip $zip $NodeDir 'node-v22.14.0-win-x64'
}
Write-Ok "Node：$(& (Join-Path $NodeDir 'node.exe') --version)"

# ---------------- Python ----------------
Write-Step "4/8 安装 Python 3.13"
if (-not (Test-Path (Join-Path $PythonDir 'python.exe'))) {
    $exe = Join-Path $DlDir 'python-3.13.10-amd64.exe'
    try {
        Get-File 'https://mirrors.huaweicloud.com/python/3.13.10/python-3.13.10-amd64.exe' $exe
    } catch {
        Get-File 'https://www.python.org/ftp/python/3.13.10/python-3.13.10-amd64.exe' $exe
    }
    Write-Info "静默安装 Python（约 30 秒）..."
    $p = Start-Process -FilePath $exe -Wait -PassThru -ArgumentList @(
        '/quiet', 'InstallAllUsers=0', 'PrependPath=0', 'Include_test=0',
        'Include_pip=1', 'Include_launcher=0', "TargetDir=`"$PythonDir`""
    )
    if ($p.ExitCode -ne 0) { throw "Python 安装失败（退出码 $($p.ExitCode)）" }
}
Write-Ok "Python：$(& (Join-Path $PythonDir 'python.exe') --version)"

# ---------------- uv ----------------
Write-Step "5/8 安装 uv（从 PyPI 直接取 Windows 二进制）"
if (-not (Test-Path (Join-Path $UvDir 'uv.exe'))) {
    $meta = Invoke-RestMethod -Uri 'https://pypi.org/pypi/uv/json' -TimeoutSec 30
    $wheel = $meta.urls | Where-Object { $_.filename -like '*win_amd64.whl' } | Select-Object -First 1
    if (-not $wheel) { throw "未找到 uv 的 Windows 安装包" }
    $whl = Join-Path $DlDir $wheel.filename
    Get-File $wheel.url $whl
    $tmp = Join-Path $Runtime ('tmp_uv_' + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
    & tar.exe -xf $whl -C $tmp
    New-Item -ItemType Directory -Path $UvDir -Force | Out-Null
    $uvExe = Get-ChildItem $tmp -Recurse -Filter 'uv.exe' | Select-Object -First 1
    if (-not $uvExe) { throw "uv 安装包中未找到 uv.exe" }
    Copy-Item $uvExe.FullName (Join-Path $UvDir 'uv.exe')
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Ok "uv：$(& (Join-Path $UvDir 'uv.exe') --version)"

Enable-Toolchain

# ---------------- MySQL ----------------
Write-Step "6/8 安装并启动 MySQL 9.6"
if (Test-Port 3306) {
    if (Test-MySqlReady) {
        Write-Ok "检测到本机已有 MySQL（root/1234），直接复用，不重复安装"
    } else {
        Write-Fail "端口 3306 已被其他进程占用，且无法用 root/1234 连接"
        Write-Info "请先停止本机 MySQL，或改 config\app.env.ps1 中的 XINGSHU_MYSQL_PORT（需同步修改各服务配置）"
        throw "MySQL 端口冲突"
    }
} else {
    if (-not (Test-Path (Join-Path $MysqlDir 'bin\mysqld.exe'))) {
        $zip = Join-Path $DlDir 'mysql-9.6.0-winx64.zip'
        Get-File 'https://cdn.mysql.com/Downloads/MySQL-9.6/mysql-9.6.0-winx64.zip' $zip
        Expand-Zip $zip $MysqlDir 'mysql-9.6.0-winx64'
    }
    if (-not (Test-Path (Join-Path $MysqlDataDir 'mysql'))) {
        Write-Info "初始化 MySQL 数据目录（首次约 20 秒）..."
        New-Item -ItemType Directory -Path $MysqlDataDir -Force | Out-Null
        & (Join-Path $MysqlDir 'bin\mysqld.exe') --initialize-insecure --basedir="$MysqlDir" --datadir="$MysqlDataDir" --console
        if ($LASTEXITCODE -ne 0) { throw "MySQL 初始化失败" }
    }
    Write-Info "启动 MySQL ..."
    $mysqlArgs = @(
        "--basedir=`"$MysqlDir`"",
        "--datadir=`"$MysqlDataDir`"",
        "--port=$($env:XINGSHU_MYSQL_PORT)",
        "--character-set-server=utf8mb4",
        "--collation-server=utf8mb4_0900_ai_ci",
        "--log-error=`"$(Join-Path $LogDir 'mysql.err.log')`""
    )
    Start-Process -FilePath (Join-Path $MysqlDir 'bin\mysqld.exe') -ArgumentList $mysqlArgs -WindowStyle Hidden | Out-Null
    if (-not (Wait-Port ([int]$env:XINGSHU_MYSQL_PORT) 90 'MySQL')) { throw "MySQL 启动失败" }
    Write-Info "设置 root 密码为 1234 ..."
    & (Join-Path $MysqlDir 'bin\mysql.exe') '--host=127.0.0.1' "--port=$env:XINGSHU_MYSQL_PORT" '--user=root' --skip-password -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '1234'; FLUSH PRIVILEGES;"
    if ($LASTEXITCODE -ne 0) { throw "MySQL 设置密码失败" }
    Write-Ok "MySQL 已启动：127.0.0.1:$($env:XINGSHU_MYSQL_PORT) root/1234"
}

# ---------------- Redis ----------------
Write-Step "7/8 安装并启动 Redis 3.0.504"
if (Test-Port 6379) {
    if (Test-RedisReady) {
        Write-Ok "检测到本机已有 Redis，直接复用"
    } else {
        throw "端口 6379 已被占用，且不是可用的 Redis，请先停止占用进程"
    }
} else {
    if (-not (Test-Path (Join-Path $RedisDir 'redis-server.exe'))) {
        $zip = Join-Path $GuideRoot 'runtime\Redis-x64-3.0.504.zip'
        if (-not (Test-Path $zip)) { throw "缺少内置 Redis 压缩包：$zip" }
        Expand-Zip $zip $RedisDir ''
    }
    New-Item -ItemType Directory -Path $RedisDataDir -Force | Out-Null
    $redisConf = Join-Path $CfgDir 'redis.conf'
    $redisDirForConf = $RedisDataDir.Replace('\', '/')
    @"
port 6379
bind 127.0.0.1
dir "$redisDirForConf"
save ""
appendonly no
"@ | Set-Content -Path $redisConf -Encoding ASCII
    Write-Info "启动 Redis ..."
    Start-Process -FilePath (Join-Path $RedisDir 'redis-server.exe') -ArgumentList "`"$redisConf`"" -WorkingDirectory $RedisDir -WindowStyle Hidden -RedirectStandardOutput (Join-Path $LogDir 'redis.out.log') -RedirectStandardError (Join-Path $LogDir 'redis.err.log') | Out-Null
    if (-not (Wait-Port 6379 30 'Redis')) { throw "Redis 启动失败" }
    Write-Ok "Redis 已启动：127.0.0.1:6379"
}

# ---------------- Elasticsearch ----------------
Write-Step "8/8 安装并启动 Elasticsearch 8.18.1"
if (Test-Port 9200) {
    if (Test-EsReady) {
        Write-Ok "检测到本机已有 Elasticsearch，直接复用"
    } else {
        throw "端口 9200 已被占用，且无法访问 _cluster/health，请先停止占用进程"
    }
} else {
    if (-not (Test-Path (Join-Path $EsDir 'bin\elasticsearch.bat'))) {
        $zip = Join-Path $DlDir 'elasticsearch-8.18.1-windows-x86_64.zip'
        Get-File 'https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.18.1-windows-x86_64.zip' $zip
        Expand-Zip $zip $EsDir 'elasticsearch-8.18.1'
    }
    New-Item -ItemType Directory -Path (Join-Path $EsDataDir 'data'), (Join-Path $LogDir 'elasticsearch') -Force | Out-Null
    $esConf = Join-Path $EsDir 'config\elasticsearch.yml'
    @"
cluster.name: xingshu-local
node.name: xingshu-node
path.data: $($EsDataDir.Replace('\', '/'))/data
path.logs: $(($LogDir.Replace('\', '/')))/elasticsearch
network.host: 127.0.0.1
http.port: 9200
discovery.type: single-node
bootstrap.memory_lock: false
xpack.security.enabled: false
xpack.security.http.ssl.enabled: false
xpack.security.transport.ssl.enabled: false
xpack.ml.enabled: false
"@ | Set-Content -Path $esConf -Encoding UTF8
    $heapDir = Join-Path $EsDir 'config\jvm.options.d'
    New-Item -ItemType Directory -Path $heapDir -Force | Out-Null
    "-Xms1g`r`n-Xmx1g" | Set-Content -Path (Join-Path $heapDir 'heap.options') -Encoding ASCII
    Write-Info "启动 Elasticsearch（首次启动约 1~2 分钟，占用内存约 1 GB）..."
    $bat = Join-Path $EsDir 'bin\elasticsearch.bat'
    Start-Process -FilePath 'cmd.exe' -ArgumentList "/c `"$bat`"" -RedirectStandardOutput (Join-Path $LogDir 'es.out.log') -RedirectStandardError (Join-Path $LogDir 'es.err.log') -WindowStyle Hidden | Out-Null
    if (-not (Wait-Url 'http://localhost:9200/_cluster/health' 300 'Elasticsearch')) {
        Write-Info "日志位置：$LogDir\es.err.log"
        throw "Elasticsearch 启动失败"
    }
    Write-Ok "Elasticsearch 已启动：http://localhost:9200（安全认证已关闭，仅本机访问）"
}

Write-Host ""
Write-Ok "基础设施安装完成。下一步：02-clone-repos.ps1"
