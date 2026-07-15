# AGENTS.md — MCP Governor

## What This Repo Is

Deployment configuration only. **No source code, no Dockerfiles, no CI/CD.** Pre-built images are pulled from `ontariolt/*` on Docker Hub. The actual image build process lives elsewhere.

## Quick Reference

```bash
# Minimal deployment (4 containers, no LLM needed)
docker compose -f docker-compose.min.yml up -d

# Full stack (9 containers, needs LLM_API_KEY in .env)
docker compose up -d

# Enterprise (same as full, mcp-governor uses enterprise-latest tag)
docker compose -f docker-compose.enterprise.yml up -d

# Run demo (requires docker compose running + python3 + PyJWT)
./demo/docker-demo.sh

# Verify gateway
curl http://localhost:7680/health
```

## Three Compose Files

| File | Services | Use Case |
|------|----------|----------|
| `docker-compose.min.yml` | gateway, OPA, ERP, CRM | Quick start, no LLM |
| `docker-compose.yml` | all 9 services | Full community stack |
| `docker-compose.enterprise.yml` | all 9 services | Enterprise — only diff is `mcp-governor:enterprise-latest` |

## Port Map

| Service | Port |
|---------|------|
| MCP Gateway | **7680** |
| OPA | 8181 |
| ERP API | 9003 |
| CRM API | 9002 |
| Admin UI | 8080 |
| Prometheus | 9090 |
| Langfuse | 3001 |

## Key Config Files

- `config/agents.yaml` — Agent identities, API keys, tool whitelists
- `config/governance.yaml` — Per-tool rate limits and sensitive params
- `config/rest_backends.yaml` — REST API backend definitions
- `config/presets/*.yaml` — Pre-configured integrations (DingTalk, Feishu, GitHub, etc.)
- `policies/*.rego` — OPA Rego policies (auth, governance, chain detection)
- `.env` — Secrets (gitignored). Copy `.env.example` to create.

## Gotchas

- **Gateway port is 7680**, not 8080. Admin UI is on 8080.
- `.env` was removed from git tracking (commit `ea95eab`). Always copy `.env.example`.
- `docker-compose.min.yml` does NOT include Admin UI — use full compose for that.
- Enterprise compose is identical to community full stack except the gateway image tag.
- Demo script (`demo/docker-demo.sh`) requires `python3` and `PyJWT` package.
- OPA policies use Rego syntax. Edit `policies/*.rego` for auth/governance changes.
- `config/agents.yaml` uses `allowed_tools` with glob patterns (e.g., `maps_*`).
- Role-based access: `viewer` (read-only), `user` (no write ops), `admin` (full access).

## Contributing

This is a closed-source project. See `CONTRIBUTING.md` — no PRs accepted. Bug reports via GitHub Issues only.
