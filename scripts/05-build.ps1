# 05 编译后端、安装前端依赖、准备 Python 虚拟环境
. (Join-Path $PSScriptRoot 'common.ps1')

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " 星枢平台 · 编译与安装依赖" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

Enable-Toolchain
if (-not (Test-Path $RepoXs)) { throw "未找到源码，请先执行 02-clone-repos.ps1" }

Write-Step "1/4 编译 Spring Boot 后端（12 个模块，首次需要下载依赖）"
Push-Location $RepoXs
try {
    & (Join-Path $MavenDir 'bin\mvn.cmd') -B '-Dmaven.test.skip=true' package 2>&1 | Tee-Object -FilePath (Join-Path $LogDir 'backend-build.log')
    if ($LASTEXITCODE -ne 0) { throw "后端编译失败，详见 $LogDir\backend-build.log" }
} finally {
    Pop-Location
}
$jars = @('xs-user', 'xs-auth', 'xs-course', 'xs-book', 'xs-exam', 'xs-data', 'xs-config', 'xs-learning')
foreach ($m in $jars) {
    $jar = Join-Path $RepoXs "$m\target\$m-1.0.0.jar"
    if (-not (Test-Path $jar)) { throw "缺少构建产物：$jar" }
}
Write-Ok "后端编译完成，8 个服务 jar 已生成"

Write-Step "2/4 准备 FastAPI .env 并安装 Python 依赖"
$envExample = Join-Path $RepoAi '.env.example'
$envTarget = Join-Path $RepoAi '.env'
if (-not (Test-Path $envTarget)) {
    if (-not (Test-Path $envExample)) { throw "缺少 $envExample" }
    Copy-Item $envExample $envTarget
    Write-Info "已从 .env.example 生成 .env"
}
# 用本地配置覆盖 Key（不写入任何仓库文件）
if ($env:XINGSHU_LLM_API_KEY) {
    $content = [System.IO.File]::ReadAllText($envTarget)
    $content = [System.Text.RegularExpressions.Regex]::Replace($content, '(?m)^OPENAI_API_KEY=.*$', "OPENAI_API_KEY=$($env:XINGSHU_LLM_API_KEY)")
    $content = [System.Text.RegularExpressions.Regex]::Replace($content, '(?m)^OPENAI_BASE_URL=.*$', "OPENAI_BASE_URL=$($env:XINGSHU_LLM_BASE_URL)")
    $content = [System.Text.RegularExpressions.Regex]::Replace($content, '(?m)^OPENAI_MODEL_NAME=.*$', "OPENAI_MODEL_NAME=$($env:XINGSHU_LLM_MODEL)")
    [System.IO.File]::WriteAllText($envTarget, $content, (New-Object System.Text.UTF8Encoding($false)))
    Write-Ok "已写入大模型 Key 到 .env"
}

Push-Location $RepoAi
try {
    & (Join-Path $UvDir 'uv.exe') sync --python "$PythonDir\python.exe" 2>&1 | Tee-Object -FilePath (Join-Path $LogDir 'python-build.log')
    if ($LASTEXITCODE -ne 0) { throw "uv sync 失败，详见 $LogDir\python-build.log" }
} finally {
    Pop-Location
}
Write-Ok "Python 虚拟环境就绪：$RepoAi\.venv"

Write-Step "3/4 安装前端依赖（npm）"
$env:npm_config_registry = 'https://registry.npmmirror.com'
Push-Location $RepoWeb
try {
    & (Join-Path $NodeDir 'npm.cmd') install --no-audit --no-fund 2>&1 | Tee-Object -FilePath (Join-Path $LogDir 'web-install.log')
    if ($LASTEXITCODE -ne 0) { throw "npm install 失败，详见 $LogDir\web-install.log" }
} finally {
    Pop-Location
}
Write-Ok "前端依赖安装完成"

Write-Step "4/4 构建前端 H5（验证工程可编译）"
Push-Location $RepoWeb
try {
    & (Join-Path $NodeDir 'npm.cmd') run build:h5 2>&1 | Tee-Object -FilePath (Join-Path $LogDir 'web-build.log')
    if ($LASTEXITCODE -ne 0) { throw "前端构建失败，详见 $LogDir\web-build.log" }
} finally {
    Pop-Location
}
Write-Ok "前端构建完成：$RepoWeb\dist\build\h5"

Write-Host ""
Write-Ok "编译与依赖安装完成。下一步：06-start-all.ps1"
