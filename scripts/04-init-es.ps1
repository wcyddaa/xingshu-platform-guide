# 04 初始化 Elasticsearch：教材、课件、向量切片（RAG 检索数据）
. (Join-Path $PSScriptRoot 'common.ps1')

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " 星枢平台 · 初始化 Elasticsearch 知识库" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

if (-not (Test-EsReady)) {
    throw "Elasticsearch 未就绪（http://localhost:9200），请先执行 01-install-infra.ps1"
}

$esUrl = 'http://localhost:9200'
$indexes = @(
    @{ Name = 'textbook_index'; Expected = 1 },
    @{ Name = 'courseware_index'; Expected = 8 },
    @{ Name = 'textbook_chunk_vector'; Expected = 2258 },
    @{ Name = 'courseware_chunk_vector'; Expected = 29 }
)

foreach ($item in $indexes) {
    $name = $item.Name
    Write-Step "导入索引 $name"
    $metaPath = Join-Path $GuideRoot "es\$name-meta.json"
    $dataPath = Join-Path $GuideRoot "es\$name-data.ndjson.gz"
    if (-not (Test-Path $metaPath) -or -not (Test-Path $dataPath)) {
        throw "缺少索引文件：$metaPath 或 $dataPath"
    }

    $meta = Get-Content $metaPath -Raw -Encoding UTF8
    try {
        Invoke-RestMethod -Uri "$esUrl/$name" -Method Put -Body $meta -ContentType 'application/json; charset=utf-8' -Headers (Es-AuthHeader) -TimeoutSec 30 | Out-Null
        Write-Info "已创建索引与字段映射"
    } catch {
        $status = $_.Exception.Response.StatusCode.value__
        if ($status -eq 400) {
            Write-Info "索引已存在，继续追加/覆盖文档"
        } else {
            throw "创建索引 $name 失败：$($_.Exception.Message)"
        }
    }

    $tmpNdjson = Join-Path $env:TEMP ("xingshu_{0}.ndjson" -f $name)
    $fs = [System.IO.File]::OpenRead($dataPath)
    try {
        $gzip = New-Object System.IO.Compression.GZipStream($fs, [System.IO.Compression.CompressionMode]::Decompress)
        $output = [System.IO.File]::Create($tmpNdjson)
        try {
            $gzip.CopyTo($output)
        } finally {
            $output.Close()
            $gzip.Close()
        }
    } finally {
        $fs.Close()
    }
    Write-Info "已解压数据（$([math]::Round((Get-Item $tmpNdjson).Length / 1MB, 1)) MB），执行 _bulk 导入 ..."

    $bulkResult = & curl.exe -s -u "${EsUser}:${EsPass}" -X POST "$esUrl/$name/_bulk?refresh=true" -H "Content-Type: application/x-ndjson" --data-binary "@$tmpNdjson"
    Remove-Item $tmpNdjson -Force -ErrorAction SilentlyContinue
    if ($LASTEXITCODE -ne 0) { throw "导入 $name 失败（curl 退出码 $LASTEXITCODE）" }
    $parsed = $bulkResult | ConvertFrom-Json
    if ($parsed.errors) {
        throw "导入 $name 存在失败文档，请检查 ES 磁盘空间与日志"
    }
    Write-Ok "$name 导入完成"
}

Write-Step "校验文档数与索引可用性"
$okAll = $true
foreach ($item in $indexes) {
    $count = (Invoke-RestMethod -Uri "$esUrl/$($item.Name)/_count" -Headers (Es-AuthHeader) -TimeoutSec 10).count
    if ($count -ge $item.Expected) {
        Write-Ok "$($item.Name)：$count 条（期望 >= $($item.Expected)）"
    } else {
        Write-Fail "$($item.Name)：仅 $count 条（期望 >= $($item.Expected)）"
        $okAll = $false
    }
}
if (-not $okAll) { throw "部分索引数据不完整" }

Write-Host ""
Write-Ok "Elasticsearch 初始化完成。下一步：05-build.ps1"
