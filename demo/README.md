# MCP Governor Demo

## 快速体验（Docker Demo）

无需 Python 环境，只需 Docker 即可体验核心功能。

### 1. 启动服务

```bash
cd mcp-governor
cp .env.example .env && vim .env  # 填入 LLM_API_KEY（可选）
docker compose -f docker-compose.min.yml up -d
```

### 2. 运行 Demo

```bash
./demo/docker-demo.sh
```

### Demo 场景

| 场景 | 功能 | 说明 |
|------|------|------|
| 健康检查 | `/health` | 验证 Gateway 运行状态 |
| 工具列表 | `tools/list` | 展示所有可用工具 |
| 注入检测 | 恶意输入拦截 | 848 条规则防护 |
| PII 脱敏 | 客户信息脱敏 | 手机号/邮箱自动屏蔽 |
| OPA 策略 | 权限控制 | 非 admin 角色调拨被拦截 |

## 完整 Demo（Python + LLM）

如需演示 LLM 集成场景（11 大场景），需要：

1. Python 3.11+
2. LLM API Key（DeepSeek / Qwen / OpenAI 等）

详见私有仓库 `demo/RUNBOOK_DOCKER.md`。

## 服务端口

| 服务 | 端口 | 说明 |
|------|------|------|
| MCP Gateway | 8080 | API 网关 |
| OPA | 8181 | 策略引擎 |
| ERP API | 9003 | 库存服务（Demo） |
| CRM API | 9002 | 客户服务（Demo） |
| Admin UI | 3002 | 管理界面 |
