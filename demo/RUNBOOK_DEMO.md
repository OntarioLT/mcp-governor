# MCP Governor — 全场景 Demo 指南

> 面向企业客户的完整 Demo 演示指南，涵盖 11 个社区场景 + 3 个企业场景。

## 前置条件

- Docker & Docker Compose
- Python 3.11+
- [uv](https://docs.astral.sh/uv/)（Python 包管理器）
- LLM API Key（见下方支持列表）
- 企业版 License

## 快速开始

按 [DEPLOYMENT_GUIDE.md — 企业版部署](../DEPLOYMENT_GUIDE.md#企业版部署) 完成 Gateway 启动后（确保根目录 `.env` 已配置 `LLM_API_KEY`）：

```bash
# 下载 Demo 包
curl -o mcp-governor-demo.zip http://localhost:7680/api/demo/package

# 解压到 REPO 根目录下
unzip mcp-governor-demo.zip
cd mcp-governor-demo

# 安装依赖并运行（agent.py 使用 REPO 根目录的 .env）
uv sync
uv run python agent.py
```

## 环境变量配置

Demo Agent 使用 REPO 根目录的 `.env`（已在 DEPLOYMENT_GUIDE.md 中配置），关键变量：

| 变量 | 说明 | 是否必填 |
|------|------|---------|
| `LLM_API_KEY` | LLM API 密钥 | 是 |
| `LLM_BASE_URL` | LLM API 端点 | 是 |
| `LLM_MODEL` | 模型名称 | 是 |
| `GATEWAY_URL` | Gateway 地址（默认 `http://localhost:7680`） | 否 |
| `JWT_SECRET_KEY` | JWT 密钥（默认 `dev-secret-change-me`） | 否 |
| `AMAP_API_KEY` | 高德地图 API Key（Scenario 2 需要） | 否 |
| `MCP_GOVERNOR_LICENSE` | 企业版 License（场景 12-14 需要） | 否 |

### LLM Provider 支持

| Provider | Base URL | Model 示例 | API Key |
|----------|----------|-----------|---------|
| **DeepSeek** | `https://api.deepseek.com/v1` | `deepseek-v4-flash` | DeepSeek API Key |
| **通义千问 Qwen** | `https://dashscope.aliyuncs.com/compatible-mode/v1` | `qwen-plus` | 阿里云 API Key |
| **Ollama（本地）** | `http://localhost:11434/v1` | `qwen3` | 无需 API Key |
| **OpenAI** | `https://api.openai.com/v1` | `gpt-4o-mini` | OpenAI API Key |
| **Google Gemini** | `https://generativelanguage.googleapis.com/v1beta/openai/` | `gemini-3.5-flash` | Google API Key |

## Demo 场景

### 社区版场景（1-11）

| 分类 | # | 场景 | 效果 |
|------|---|------|------|
| **工具路由** | 1 | 统一接入 | LLM 调用内部 ERP 查询库存，返回真实数据 |
| | 2 | 多源聚合 | CRM + ERP + AMAP 距离计算，就近仓库发货 |
| | 3 | REST 虚拟化 | 零配置 REST API → MCP tools |
| **安全防护** | 4 | 注入防护 | 848 条规则拦截恶意 prompt 注入攻击 |
| | 5 | PII 脱敏 | 客户手机号/邮箱自动屏蔽 |
| **权限控制** | 6 | OPA 策略 | 非 admin 角色调用 `transfer_stock` 被拦截 |
| | 7 | Agent 隔离 | hr_agent 被拒（工具无授权），user 角色被拒（无写权限） |
| | 8 | 用户级控制 | 敏感工具按 user_id 白名单控制 |
| **可观测性** | 9 | 审计追溯 | 结构化日志含 Agent 身份 + 调用轨迹 |
| | 10 | 可观测性 | 实时监控面板（Prometheus 指标） |
| **流量控制** | 11 | 限流 | Token Bucket 限流（per-agent + per-tool） |

### 企业版场景（12-14，需要 License）

| # | 场景 | 效果 |
|---|------|------|
| 12 | OAuth 2.1 / OIDC SSO | 展示企业 IdP 集成能力 |
| 13 | Ed25519 审计签名 | 防篡改审计链验证 |
| 14 | Chain Detector | 多步攻击模式检测 |

### 运行特定场景

```bash
# 只运行场景 1（库存查询）
uv run python agent.py -sc 1

# 运行场景 1、4、6
uv run python agent.py -sc 1,4,6

# 运行所有场景（默认）
uv run python agent.py
```

## 服务端口

| 服务 | 端口 | 说明 |
|------|------|------|
| MCP Governor | :7680 | API Gateway |
| Admin UI | :8080 | Web 管理后台（含监控面板） |
| ERP API | :9003 | 库存服务（Demo） |
| CRM API | :9002 | 客户服务（Demo） |
| OPA | :8181 | 策略引擎 |
| Prometheus | :9090 | 指标监控 |

## 故障排查

### Demo 连接 Gateway 失败

```bash
# 确认 Gateway 在运行
curl http://localhost:7680/health

# 确认 .env 中 GATEWAY_URL 正确
cat .env | grep GATEWAY_URL
```

### LLM API 超时

```bash
# 测试 LLM 连接
curl "$LLM_BASE_URL/models" -H "Authorization: Bearer $LLM_API_KEY"

# 如果使用 Ollama，确保服务在运行
curl http://localhost:11434/v1/models
```

### 企业场景（12-14）被跳过

确保 `.env` 中配置了有效的 `MCP_GOVERNOR_LICENSE`，并且 Gateway 容器已重启使 License 生效。

### 依赖安装失败

```bash
# 确保 uv 已安装
uv --version

# 重新安装依赖
uv sync --refresh
```

## REST → MCP 动态虚拟化（可选）

将任意 REST API 动态代理为 MCP tools，无需手写 binding 或预生成 manifest。

### 配置方式

**方式一：Admin UI 运行时注册（推荐）**

1. 打开 http://localhost:8080 → Tools → + Register
2. 选择 **REST (运行时)** tab
3. 填写 Base URL、Namespace，可选 OpenAPI URL
4. 点击 Register，工具立即出现在列表中

**方式二：配置文件（启动时加载）**

在 Gateway 容器的 `config/rest_backends.yaml` 中添加：

```yaml
backends:
  - base_url: http://your-api:8080
    namespace: api           # tool name 前缀
    auth:
      type: bearer
      token: ${API_TOKEN}
    include: ["/v1/*"]       # 只暴露 /v1/ 下的接口
```

重启 Gateway 加载配置。

### 验证

```bash
curl -s http://localhost:7680/mcp \
  -H "Content-Type: application/json" \
  -H "Authorization: ApiKey <your-api-key>" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}' | python3 -m json.tool | grep "rest_proxy"
```

## 更多信息

- 完整部署指南：[`DEPLOYMENT_GUIDE.md`](../DEPLOYMENT_GUIDE.md)
