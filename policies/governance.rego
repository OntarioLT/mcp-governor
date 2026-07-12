package mcp.governance

default allow = false

allow if {
    count(deny) == 0
}

# Rule 1: Block destructive operations (PRD §7.2)
deny contains reason if {
    reason := "destructive operation blocked"
    input.server.risk.integrity == "destructive"
    not input.privileged
}

# Rule 2: Block write operations from public sources (PRD §7.2)
deny contains reason if {
    reason := "write operation blocked for public server"
    input.server.tags[_] == "src:public"
    input.tool_risk.integrity != "read-only"
}

# Rule 3: Restricted data isolation (PRD §7.2)
deny contains reason if {
    reason := "restricted data requires internal network"
    input.server.risk.confidentiality == "restricted"
    input.network != "internal"
}

# Rule 4: PII approval required (PRD §7.2)
deny contains reason if {
    reason := "PII access requires approval"
    input.server.risk.pii_scope != "none"
    not input.pii_approved
}

# Rule 5: Block beta in production (PRD §7.2)
deny contains reason if {
    reason := "beta server blocked in production"
    input.server.tags[_] == "life:beta"
    input.environment == "prod"
}
