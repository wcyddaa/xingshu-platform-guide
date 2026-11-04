# 星枢教育平台 · 评委本地复现指引

本仓库只做一件事：**让评委在自己的 Windows 电脑上，用真实环境（不用 Docker、不用 Mock），把这个平台完整跑起来并验证。**

源码在三个公开仓库中，本仓库负责：一键安装同版本基础设施、初始化数据库表结构与 admin001、启动全部服务、自动验证。

| 仓库 | 说明 | 地址 |
| --- | --- | --- |
| xs-platform | Spring Boot 4.1 微服务后端（8 个服务） | https://github.com/wcyddaa/xs-platform |
| ai-assistant | uni-app + Vue3 + Vite5 前端（H5） | https://github.com/wcyddaa/ai-assistant |
| fastapi-ai-assistant | FastAPI + LangGraph 智能体服务 | https://github.com/wcyddaa/fastapi-ai-assistant |
| xingshu-platform-guide | 本指引仓库（脚本、种子数据、Actions） | https://github.com/wcyddaa/xingshu-platform-guide |

> 三个源码仓库均为公开仓库，**无需授权、无需账号**，直接 `git clone` 即可。

---

## 一、评委只需 4 步

### 第 1 步：准备一台 Windows 电脑

- Windows 10 / 11，64 位
- 内存 ≥ 8 GB（推荐 16 GB，Elasticsearch 独占约 1 GB）
- 磁盘剩余 ≥ 10 GB
- 已安装 [Git for Windows](https://git-scm.com/download/win)
- 首次执行需联网下载约 1.3 GB（JDK、Maven、Node、Python、MySQL、Elasticsearch 等）

不需要提前安装 JDK、Maven、Node、Python、MySQL、Redis、Elasticsearch，也不需要 Docker，脚本会全部装到独立目录，**不会污染系统环境变量**。

### 第 2 步：克隆本指引仓库

```powershell
git clone https://github.com/wcyddaa/xingshu-platform-guide.git
cd xingshu-platform-guide
```

如果本机配置过代理导致 clone 超时，可在命令前加 `-c http.proxy= -c https.proxy=`：

```powershell
git -c http.proxy= -c https.proxy= clone https://github.com/wcyddaa/xingshu-platform-guide.git
```

### 第 3 步（可选，强烈建议）：填入你自己的模型 Key

打开 `%USERPROFILE%\XingShuEnv\config\app.env.ps1`（首次运行脚本后会自动生成），填写大模型 Key：

```powershell
$env:XINGSHU_LLM_API_KEY = '你的大模型 Key'  # 阿里云百炼 DashScope，qwen-plus
```

- Key 只写入你本机数据库和进程环境变量，**不会提交到任何仓库**。
- 不填也能启动平台、登录、浏览数据；只是智能体问答会提示缺少模型凭据。
- 也可以启动后在**管理员端「模型配置」**页面填写并发布，效果相同。

**向量模型 Key 不再使用环境变量**，统一在管理员端「模型配置」页面的 **EMBEDDING** 分类中填写
（硅基流动 SiliconFlow、`BAAI/bge-m3`、1024 维），测试通过后发布。xs-book 会从 xs-config
的受保护内部接口读取，配置后**无需重启、无需重跑脚本**。

### 第 4 步：双击 `一键启动.bat`

或在 PowerShell 中执行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\one-click.ps1
```

脚本会依次完成：

```
环境自检 → 安装基础设施 → 下载三个源码仓库 → 初始化 MySQL → 初始化 ES 知识库
→ 编译后端/安装前端/准备 Python → 启动 13 个进程 → 自动验证
```

首次约 15~30 分钟（取决于网速），之后重启只需 `scripts\06-start-all.ps1`，约 2 分钟。

结束时看到：

```
验证结果：xx 项通过，0 项失败
打开浏览器访问：http://localhost:5173
```

浏览器打开 <http://localhost:5173> 即可开始演示。

---

## 二、初始账号与前端建号

数据库**只内置一个管理员账号**，其余账号、教学班全部由评委在前端创建（不使用任何导出数据）。

| 角色 | 账号 | 密码 | 说明 |
| --- | --- | --- | --- |
| 管理员 | `admin001` | `123456` | 用于创建教师/学生、教学班、配置模型 |

### 评委在前端完成剩余配置（约 3 分钟）

1. **管理员登录** → 「模型配置」→ 填入自己的模型 Key → 测试 → 发布（若已在 `app.env.ps1` 填 Key，可跳过）。
2. **用户管理** → 新建教师账号（如 `teacher01`）、新建学生账号（如 `student01`），设置密码。
3. **教学班管理** → 新建教学班 → 指定教师 → 把学生加入教学班。
4. **教师登录** → 「教学班」→ 「智能体配置」→ 选择已发布的模型、设置班级 Token 额度 → 启用。
5. **学生登录** → 选择所属教学班 → 「智能问答」→ 提问教材/课件内容（走 RAG，检索 ES 中的真实切片）。
6. 学生加入多个教学班时，可切换班级；智能体、学习报告、提问记录按教学班隔离。

> ES 知识库（教材、课件、2258 条向量切片）已预先导入，无需评委上传即可测试 RAG 问答。
> 学生必须先被管理员加入教学班，才能在问答页看到班级智能体实例。

---

## 三、脚本清单（可分步执行）

所有脚本位于 `scripts\`，可单独运行，重复执行会自动跳过已完成步骤。

| 脚本 | 作用 | 关键校验 |
| --- | --- | --- |
| `00-check-env.ps1` | 系统、磁盘、Git、端口自检 | 13 个端口空闲情况 |
| `01-install-infra.ps1` | 下载并启动 JDK21 / Maven / Node22 / Python3.13 / uv / MySQL9.6 / Redis3 / ES8.18 | 每个组件版本与端口 |
| `02-clone-repos.ps1` | 克隆三个公开源码仓库到 `%USERPROFILE%\XingShuEnv\src` | 仓库完整性 |
| `03-init-db.ps1` | 导入 `sql\seed.sql`（6 个库的表结构 + admin001） | admin001 是否存在、6 个库是否建表 |
| `04-init-es.ps1` | 创建 4 个索引并导入真实文档（含 2258 条向量切片） | 文档条数 |
| `05-build.ps1` | Maven 打包、npm 安装并构建 H5、uv 同步 Python 依赖 | 8 个 jar、前端 dist |
| `06-start-all.ps1` | 启动 8 个 Spring Boot 服务 + FastAPI + 前端 | 13 个端口 |
| `07-stop-all.ps1` | 停止应用（`-IncludeInfra` 连基础设施一起停） | — |
| `verify.ps1` | 逐项验证并输出 PASS/FAIL | 登录、权限隔离、ES/MySQL/Redis |
| `one-click.ps1` | 按顺序执行以上全部 | 最终 PASS/FAIL |

单独验证（服务已启动时）：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\verify.ps1
```

### 常用命令

```powershell
# 只启动服务（不重新安装/编译）
.\scripts\06-start-all.ps1

# 停止应用，保留 MySQL/Redis/ES
.\scripts\07-stop-all.ps1

# 全部停止
.\scripts\07-stop-all.ps1 -IncludeInfra

# 重置数据库（恢复为仅 admin001）
.\scripts\03-init-db.ps1
.\scripts\04-init-es.ps1

# 彻底重装：停止全部并删除运行目录，再双击一键启动
.\scripts\07-stop-all.ps1 -IncludeInfra
Remove-Item "$env:USERPROFILE\XingShuEnv" -Recurse -Force
```

> PowerShell 如果提示“禁止运行脚本”，请使用 `powershell -NoProfile -ExecutionPolicy Bypass -File ...`，或执行一次
> `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`。

---

## 四、端口与组件

| 端口 | 服务 | 说明 |
| --- | --- | --- |
| 5173 | ai-assistant | 前端 H5（Vite dev server） |
| 8000 | fastapi-ai-assistant | LangGraph 智能体，Swagger：`/docs` |
| 8080 | xs-user | 用户/学生/教师 |
| 8081 | xs-auth | 登录、Token、鉴权 |
| 8082 | xs-course | 课程、教学班、章节 |
| 8083 | xs-book | 教材、课件、ES 检索、RAG |
| 8084 | xs-exam | 作业、考试、批改 |
| 8085 | xs-data | 数据统计、Token 汇总（Redis db1） |
| 8086 | xs-config | 模型配置、教学班智能体实例、额度 |
| 8087 | xs-learning | 学习记录、能力图谱、学情报告 |
| 3306 | MySQL 9.6.0 | 6 个业务库 |
| 6379 | Redis 3.0.504 | 会话、缓存、统计 |
| 9200 | Elasticsearch 8.18.1 | 教材/课件/向量索引 |

### 版本对照（脚本安装 vs 开发机）

| 组件 | 本指引安装 | 开发机 | 说明 |
| --- | --- | --- | --- |
| JDK | Temurin 21 | JDK 25 | 项目编译目标为 Java 21，21 可直接运行 |
| Maven | 3.9.9 | IDEA 内置 3.x | 构建结果一致 |
| Node.js | 22.14.0 LTS | 26.12.1 | Vite5 均兼容 |
| Python | 3.13.10 | 3.13.x | 与 `.python-version` 一致 |
| MySQL | 9.6.0 | 9.6.0 | 完全一致（含排序规则） |
| Redis | 3.0.504 | 3.0.504 | 完全一致 |
| Elasticsearch | 8.18.1 | 8.18.1 | 完全一致；评委环境关闭安全认证并限制 1 GB 堆 |

### 运行目录结构（`%USERPROFILE%\XingShuEnv`）

```
XingShuEnv\
├─ src\                    三个源码仓库
│  ├─ xs-platform\
│  ├─ ai-assistant\
│  └─ fastapi-ai-assistant\
├─ jdk21\ maven\ node\ python313\ uv\ mysql\ redis\ elasticsearch\
├─ data\                   MySQL / Redis / ES 数据
├─ downloads\              安装包缓存（删除后重跑会重新下载）
├─ logs\                   每个服务的 out/err 日志
├─ pids\                   进程 PID（供停止脚本使用）
└─ config\
   ├─ app.env.ps1          模型 Key 配置（本机私有）
   └─ redis.conf
```

---

## 五、自动验证覆盖范围

`verify.ps1` 会检查 30+ 项，全部 PASS 才算部署成功：

- 13 个端口全部监听
- MySQL 六个库可连接且已建表，`admin001` 存在
- Redis `PING` 返回 `PONG`
- ES 集群 `green/yellow`，4 个索引文档数达到种子数据量
- 管理员可登录并拿到 Token
- 管理员带 Token 可访问 xs-config，匿名访问被拒绝
- FastAPI `/health` 返回 `ok`
- 前端首页 HTTP 200

> 问答链路的真实模型调用需要有效 Key。为避免把“Key 无效”误判为部署失败，`verify.ps1` 不强制调用大模型；填好 Key 后在页面提问即可完成端到端验证。

---

## 六、GitHub Actions 兜底验证

本仓库内置 `.github/workflows/verify.yml`，在每次 push / PR / 手动触发 / 每周定时运行时，自动验证：

1. **三条源码仓库可构建**：分别 clone 公开仓库，JDK 21 编译全部后端模块、Node 22 构建 H5、Python 3.13 同步依赖并编译。
2. **指引仓库自身完整**：`seed.sql` 六个库齐全、ES 压缩包可正常解压、所有脚本通过 PowerShell 语法解析、README 中的仓库地址有效。
3. **密钥泄漏扫描**：扫描三个源码仓库，若发现 `sk-` 形式的真实 Key 立即失败。
4. **Windows 脚本自检**：在 `windows-latest` 上真实执行 `00-check-env.ps1`。

查看结果：本仓库 **Actions** 标签页 → `Verify Guide & Source Repos`。

即使评委本地环境特殊，Actions 也能证明：源码可编译、种子数据完整、脚本语法正确、仓库无密钥泄漏。

---

## 七、常见问题（按现象排查）

### 1. `git clone` 报 `Could not connect to server 127.0.0.1:xxxx`

本机 Git 配置了失效代理。

```powershell
git config --global --unset http.proxy
git config --global --unset https.proxy
```

本仓库脚本调用 git 时已自动忽略代理（`-c http.proxy=`）。

### 2. 某个端口被占用

```powershell
.\scripts\07-stop-all.ps1
# 或查看占用者
Get-NetTCPConnection -State Listen -LocalPort 8080 | Select-Object OwningProcess
```

如果占用者是你本机已有的 MySQL / Redis / ES，脚本会**复用**：MySQL 要求 `root/1234`；Redis、ES 要求可直接访问。

### 3. MySQL 无法用 root/1234 连接

- 脚本只在 3306 **空闲**时安装便携版 MySQL，并设置 `root/1234`。
- 若你本机已有 MySQL 且密码不是 `1234`，请先停止它，或修改 `scripts\01-install-infra.ps1` 中 `Test-MySqlReady` 与 `03-init-db.ps1` 的连接参数。

### 4. Elasticsearch 启动失败

查看 `%USERPROFILE%\XingShuEnv\logs\es.err.log`：

- `not enough memory`：至少留 4 GB 空闲内存；堆已固定 1 GB。
- 端口冲突：先执行 `07-stop-all.ps1 -IncludeInfra`。
- 数据损坏：删除 `XingShuEnv\data\elasticsearch` 后重跑 `01-install-infra.ps1`。

### 5. 后端 8083（xs-book）启动失败

- 必须以 `xs-platform` 仓库根目录为工作目录启动（脚本已处理）。
- 上传目录 `uploads\` 会自动创建。
- ES 必须是 `http://localhost:9200` 且安全认证关闭（脚本已配置）。

### 6. 前端能打开但接口 401 / 一直转圈

Token 过期或后端未启动。重新登录；并确认 8080-8087、8000 全部在监听。日志在 `XingShuEnv\logs\`。

### 7. Redis 报 `MISCONF Redis is configured to save RDB snapshots`

本项目不需要持久化，脚本生成的 `redis.conf` 已设置 `save ""`、`dir` 指向可写目录，不会再触发该错误。若你复用了自有 Redis，请执行：

```powershell
redis-cli CONFIG SET stop-writes-on-bgsave-error no
```

### 8. `npm install` 很慢或失败

脚本已设置 `registry=https://registry.npmmirror.com`。仍失败时可手动：

```powershell
cd $env:USERPROFILE\XingShuEnv\src\ai-assistant
npm config set registry https://registry.npmmirror.com
npm install --no-audit --no-fund
```

### 9. `uv sync` 失败

重试 `05-build.ps1`；确认网络可访问 PyPI。脚本使用本地 Python 3.13，不会触发 uv 从 GitHub 下载解释器。

### 10. 智能体问答提示“未配置模型 Key”

- **大模型 Key**：在 `XingShuEnv\config\app.env.ps1` 填好后重跑 `03-init-db.ps1` 并重启 `06-start-all.ps1`；或直接在管理员端「模型配置」页面填写、测试、发布（无需重启）。
- **向量模型 Key**：在管理员端「模型配置」→ **EMBEDDING** 填写 SiliconFlow `BAAI/bge-m3` 密钥，测试通过后发布。密钥只保存在本机数据库，由 xs-config 内部接口提供给 xs-book，配置后下一次问答自动生效。

### 11. 教学班选不到智能体

- 学生账号必须已被管理员加入某个教学班。
- 教师需先在该教学班下创建并启用智能体实例（初始数据库为空，需在前端配置一次）。

### 12. 想从头再来

```powershell
.\scripts\07-stop-all.ps1 -IncludeInfra
Remove-Item "$env:USERPROFILE\XingShuEnv" -Recurse -Force
```

然后重新双击 `一键启动.bat`。

---

## 八、安全说明

- 本指引仓库**不包含任何真实 API Key**。`app.env.example` 只有占位符。
- 三个源码仓库已完成脱敏：`application.yaml` 不再包含真实模型 Key（仅保留 `not-configured` 占位），ES 密码改为 `${环境变量:默认值}`，`init.sql` / 种子数据中的 Key 已置空。
- 评委填写的**大模型 Key** 只存在于本机 `%USERPROFILE%\XingShuEnv\config\app.env.ps1`、本机数据库和进程环境变量中。
- **向量模型 Key 不经过环境变量和配置文件**：只保存在本机数据库，由 xs-config 的 `/api/model-config/agent-config` 内部接口提供，调用方必须携带 `X-Internal-Token`；普通用户 Token 无法读取，管理端列表返回的密钥已脱敏。
- 服务端不在日志中输出完整密钥（FastAPI 使用掩码，xs-book 只记录模型名与地址），密钥仅在内存中缓存，不写入任何仓库。
- 评委环境 Elasticsearch 关闭安全认证并只监听 `127.0.0.1`，不对外暴露；仅用于本地演示。
- 内部服务令牌 `xingshu-internal-2026` 是演示用的固定值；携带该令牌的请求只接受来自 `127.0.0.1` / `::1` 的本机调用，局域网内其它机器无法读取模型密钥。
