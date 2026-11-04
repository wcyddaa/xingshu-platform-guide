# 03 初始化数据库：六个库的表结构 + admin001 初始账号
. (Join-Path $PSScriptRoot 'common.ps1')

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " 星枢平台 · 初始化 MySQL（表结构 + admin001）" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

if (-not (Test-Port ([int]$env:XINGSHU_MYSQL_PORT))) {
    throw "MySQL 未启动，请先执行 01-install-infra.ps1"
}

Enable-Toolchain
$mysqlExe = Join-Path $MysqlDir 'bin\mysql.exe'
if (-not (Test-Path $mysqlExe)) {
    $cmd = Get-Command mysql.exe -ErrorAction SilentlyContinue
    if (-not $cmd) { throw "未找到 mysql 客户端，请先执行 01-install-infra.ps1" }
    $mysqlExe = $cmd.Source
}

$seed = Join-Path $GuideRoot 'sql\seed.sql'
if (-not (Test-Path $seed)) { throw "缺少种子数据：$seed" }

Write-Step "1/3 导入 seed.sql（六个数据库的表结构 + admin001 初始账号）"
$env:MYSQL_PWD = '1234'
Get-Content $seed -Encoding UTF8 | & $mysqlExe '--host=127.0.0.1' "--port=$env:XINGSHU_MYSQL_PORT" '--user=root' --default-character-set=utf8mb4
if ($LASTEXITCODE -ne 0) { throw "导入 seed.sql 失败" }
Write-Ok "seed.sql 导入完成（仅内置 admin001，其余账号/教学班由评委在前端创建）"

Write-Step "2/3 校验初始账号"
$sqlCheck = @'
SELECT CONCAT('管理员账号=', COUNT(*)) FROM `xs-user`.`user` WHERE username='admin001';
SELECT CONCAT('教学班数=', COUNT(*)) FROM `xs-course`.class_info;
SELECT CONCAT('模型配置数=', COUNT(*)) FROM `xs-config`.model_config;
SELECT CONCAT('智能体实例数=', COUNT(*)) FROM `xs-config`.agent_class_config;
'@
$checkFile = Join-Path $env:TEMP 'xingshu_seed_check.sql'
Set-Content -Path $checkFile -Value $sqlCheck -Encoding UTF8
Get-Content $checkFile -Raw | & $mysqlExe '--host=127.0.0.1' "--port=$env:XINGSHU_MYSQL_PORT" '--user=root' -N
Remove-Item $checkFile -Force -ErrorAction SilentlyContinue

Write-Step "3/3 如已填写 Key，则写入数据库（可跳过，改在页面填写）"
$llmKey = $env:XINGSHU_LLM_API_KEY
$embKey = $env:XINGSHU_EMBEDDING_API_KEY
if ([string]::IsNullOrWhiteSpace($llmKey) -and [string]::IsNullOrWhiteSpace($embKey)) {
    Write-Info "未检测到 Key，跳过。启动后可在管理员端「模型配置」页面填写并发布。"
} else {
    $llmBase = $env:XINGSHU_LLM_BASE_URL
    $llmModel = $env:XINGSHU_LLM_MODEL
    $embBase = $env:XINGSHU_EMBEDDING_BASE_URL
    $embModel = $env:XINGSHU_EMBEDDING_MODEL
    $safeLlm = $llmKey -replace "'", "''"
    $safeEmb = $embKey -replace "'", "''"
    $safeLlmBase = $llmBase -replace "'", "''"
    $safeLlmModel = $llmModel -replace "'", "''"
    $safeEmbBase = $embBase -replace "'", "''"
    $safeEmbModel = $embModel -replace "'", "''"

    $keySql = ''
    if (-not [string]::IsNullOrWhiteSpace($safeLlm)) {
        $keySql += @"
INSERT INTO ``xs-config``.model_config (config_type, agent_name, model_name, base_url, api_key, temperature, max_tokens, test_status, enabled)
SELECT 'LLM', 'chat', '$safeLlmModel', '$safeLlmBase', '$safeLlm', 0.3, 4096, 'success', 1
WHERE NOT EXISTS (SELECT 1 FROM ``xs-config``.model_config WHERE config_type='LLM' AND agent_name='chat');
UPDATE ``xs-config``.model_config SET api_key='$safeLlm', base_url='$safeLlmBase', model_name='$safeLlmModel', test_status='success', enabled=1 WHERE config_type='LLM' AND agent_name='chat';
UPDATE ``xs-config``.agent_class_config SET api_key='$safeLlm';
"@
    }
    if (-not [string]::IsNullOrWhiteSpace($safeEmb)) {
        $keySql += @"
INSERT INTO ``xs-config``.model_config (config_type, agent_name, model_name, base_url, api_key, temperature, max_tokens, test_status, enabled)
SELECT 'EMBEDDING', 'default', '$safeEmbModel', '$safeEmbBase', '$safeEmb', 0.0, 0, 'success', 1
WHERE NOT EXISTS (SELECT 1 FROM ``xs-config``.model_config WHERE config_type='EMBEDDING');
"@
    }
    $keyFile = Join-Path $env:TEMP 'xingshu_inject_key.sql'
    Set-Content -Path $keyFile -Value $keySql -Encoding UTF8
    Get-Content $keyFile -Raw | & $mysqlExe '--host=127.0.0.1' "--port=$env:XINGSHU_MYSQL_PORT" '--user=root' --default-character-set=utf8mb4
    if ($LASTEXITCODE -ne 0) { throw "写入模型 Key 失败" }
    Remove-Item $keyFile -Force -ErrorAction SilentlyContinue
    Write-Ok "已将模型 Key 写入本机数据库（管理员端可直接看到）"
}

Write-Host ""
Write-Ok "数据库初始化完成。下一步：04-init-es.ps1"
