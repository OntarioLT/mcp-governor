# MCP Governor 部署指南

## 前置条件

- Docker 20.10+
- Docker Compose v2+
- 4GB+ 可用内存

## 快速开始（推荐）

### 1. 克隆仓库

```bash
git clone https://github.com/OntarioLT/mcp-governor.git
cd mcp-governor
```

### 2. 启动服务

```bash
docker compose -f docker-compose.min.yml up -d
```

### 3. 验证部署

```bash
curl http://localhost:7680/health
# 期望输出: {"status":"ok","version":"1.0.0"}
```

## 完整部署（含监控）

如需 Prometheus + Grafana 监控、Langfuse LLM 追踪和 Admin UI 管理界面：

### 1. 配置环境变量

```bash
cp .env.example .env
```

编辑 `.env`，填入 LLM API Key：

```env
LLM_API_KEY=sk-your-key-here
```

### 2. 启动服务

```bash
docker compose up -d
```

### 3. 访问 Admin UI

浏览器打开 http://localhost:8080 即可访问管理界面。

### 服务端口

| 服务 | 端口 | 说明 |
|------|------|------|
| MCP Governor | 7680 | API Gateway |
| OPA | 8181 | 策略引擎 |
| ERP API | 9003 | 库存服务（Demo） |
| CRM API | 9002 | 客户服务（Demo） |
| Prometheus | 9090 | 指标监控 |
| Grafana | 3000 | 监控面板（admin/admin） |
| Langfuse | 3001 | LLM 追踪 |
| Admin UI | 8080 | 管理界面 |

## 对接 AI Agent

### Claude Desktop / DIFY / 自研 Agent

在 MCP 客户端配置中添加：

```json
{
  "mcpServers": {
    "mcp-governor": {
      "url": "http://<your-host>:7680/mcp",
      "transport": "streamable-http",
      "headers": {
        "Authorization": "ApiKey <your-api-key>"
      }
    }
  }
}
```

### 认证方式

| 方式 | Header 格式 | 适用场景 |
|------|------------|---------|
| API Key | `Authorization: ApiKey <key>` | 外部平台对接 |
| JWT | `Authorization: Bearer <token>` | 内部测试 |

## 配置 Agent 权限

编辑 `config/agents.yaml`：

```yaml
agents:
  my_agent:
    api_key: "my-secret-key"
    allowed_tools:
      - "erp.query_stock"
      - "crm.get_customer"
    rate_limit: 1000/hour
```

## 常见问题

### Gateway 连接后端失败

确保 ERP/CRM 服务已启动：

```bash
curl http://localhost:9003/health
curl http://localhost:9002/health
```

### JWT 认证失败

确保使用正确的 JWT Secret（默认: `dev-secret-change-me`）。

## 企业版部署

企业版提供完整的商业功能，包括 OAuth SSO、Ed25519 审计签名、Chain Detector 等。

### 前置条件

1. 从商务获取 License 文件 (`license.key`)
2. 获取私有 Registry 访问权限

### 部署步骤

#### 1. 配置私有 Registry

```bash
export ENTERPRISE_REGISTRY=registry.cn-hangzhou.aliyuncs.com/your-namespace
docker login registry.cn-hangzhou.aliyuncs.com
```

#### 2. 配置环境变量

```bash
cp .env.example .env
```

编辑 `.env`，添加 License：

```env
LLM_API_KEY=sk-your-key-here
MCP_GOVERNOR_LICENSE=<your-license-key>
```

#### 3. 启动服务

```bash
docker compose -f docker-compose.enterprise.yml up -d
```

#### 4. 验证企业版

```bash
curl -s http://localhost:7680/config/enterprise
# 期望输出: {"enterprise": true, "features": {"oauth": true, ...}}
```

### 企业版 vs 社区版

| 功能 | 社区版 | 企业版 |
|------|--------|--------|
| 注入防护 | ✅ | ✅ |
| PII 脱敏 | ✅ | ✅ |
| 审计追溯 | ✅ | ✅ + Ed25519 签名 |
| 鉴权 | JWT + API Key | + OAuth 2.1/OIDC SSO |
| Admin UI | 基础功能 | 完整功能 |

### 获取企业版 License

📬 企业服务（含商业授权/定制/SLA）：<br>&emsp;Global: recursiontian@gmail.com (Response within 24-48h on weekdays)<br>&emsp;国内联系: 关注我的个人公众号「微碰旅行」→ 菜单栏「更多」→「企业服务」
