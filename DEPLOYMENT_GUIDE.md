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

### 2. 配置环境变量

```bash
cp .env.example .env
```

编辑 `.env`，填入 LLM API Key：

```env
LLM_API_KEY=sk-your-key-here
```

### 3. 启动服务

```bash
docker compose -f docker-compose.min.yml up -d
```

### 4. 验证部署

```bash
curl http://localhost:8080/health
# 期望输出: {"status":"ok","version":"1.0.0"}
```

## 完整部署（含监控）

如需 Prometheus + Grafana 监控和 Langfuse LLM 追踪：

```bash
docker compose up -d
```

### 服务端口

| 服务 | 端口 | 说明 |
|------|------|------|
| MCP Governor | 8080 | API Gateway |
| OPA | 8181 | 策略引擎 |
| ERP API | 9003 | 库存服务（Demo） |
| CRM API | 9002 | 客户服务（Demo） |
| Prometheus | 9090 | 指标监控 |
| Grafana | 3000 | 监控面板（admin/admin） |
| Langfuse | 3001 | LLM 追踪 |
| Admin UI | 3002 | 管理界面 |

## 对接 AI Agent

### Claude Desktop / DIFY / 自研 Agent

在 MCP 客户端配置中添加：

```json
{
  "mcpServers": {
    "mcp-governor": {
      "url": "http://<your-host>:8080/mcp",
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

## 企业版

如需以下商业功能，请联系商务：

- OAuth/OIDC SSO 集成
- Ed25519 审计签名
- Chain Detector 链路风险检测
- 源码授权与二次开发
- 企业定制部署 + SLA 支持

📬 关注微信公众号「微碰旅行」→ 菜单栏「更多」→「企业服务」
