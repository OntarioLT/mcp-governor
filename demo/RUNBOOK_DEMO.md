# MCP Governor — 全场景 Demo 指南

> 面向企业客户的完整 Demo 演示指南，涵盖 11 个社区场景 + 3 个企业场景。

## 快速开始

```bash
# 1. 克隆公开 REPO（含 Demo 指南）
git clone https://github.com/OntarioLT/mcp-governor.git
cd mcp-governor

# 2. 启动企业版 Gateway（需要 MCP_GOVERNOR_LICENSE）
docker compose -f docker-compose.enterprise.yml up -d

# 3. 下载 Demo 包
curl -O http://localhost:7680/api/demo/package

# 4. 解压并运行
unzip mcp-governor-demo.zip
cd mcp-governor-demo
uv sync
uv run python demo/agent.py
```

## 前置条件

- Docker & Docker Compose
- Python 3.11+
- [uv](https://docs.astral.sh/uv/)（Python 包管理器）
- LLM API Key（见下方支持列表）
- 企业版 License（联系商务获取：recursiontian@gmail.com）

## 环境变量配置

解压 Demo 包后，编辑 `.env` 文件：

```bash
# 必填：LLM 配置（支持所有 OpenAI 兼容 API）
LLM_API_KEY=your-api-key
LLM_BASE_URL=https://api.deepseek.com/v1
LLM_MODEL=deepseek-v4-flash

# 必填：Gateway 地址
GATEWAY_URL=http://localhost:7680

# 可选：JWT 密钥（默认 dev-secret-change-me）
JWT_SECRET_KEY=myJWT123

# 可选：高德地图 API Key（Scenario 2 多源聚合需要）
AMAP_API_KEY=your-amap-key

# 可选：Langfuse 追踪
LANGFUSE_PUBLIC_KEY=pk-lf-xxx
LANGFUSE_SECRET_KEY=sk-lf-xxx
LANGFUSE_HOST=http://localhost:3001
```

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
| | 10 | 可观测性 | Prometheus + Grafana 实时监控 |
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
uv run python demo/agent.py -sc 1

# 运行场景 1、4、6
uv run python demo/agent.py -sc 1,4,6

# 运行所有场景（默认）
uv run python demo/agent.py
```

## 服务端口

| 服务 | 端口 | 说明 |
|------|------|------|
| MCP Governor | :7680 | API Gateway |
| Admin UI | :8080 | Web 管理后台 |
| ERP API | :9003 | 库存服务（Demo） |
| CRM API | :9002 | 客户服务（Demo） |
| OPA | :8181 | 策略引擎 |
| Prometheus | :9090 | 指标监控 |
| Grafana | :3000 | 监控面板 |

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

## 更多信息

- 完整部署指南：[`DEPLOYMENT_GUIDE.md`](../DEPLOYMENT_GUIDE.md)
