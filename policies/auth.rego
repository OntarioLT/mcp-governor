package mcp.auth

default allow = false

allow if {
    count(deny) == 0
}

# Allow health check
allow if {
    input.method == "GET"
    input.path == "/health"
}

# Allow normal MCP requests (tools/list, tools/call, etc.)
allow if {
    input.path == "/mcp"
    count(deny) == 0
}

# RBAC: viewer can only do tools/list (no tools/call)
deny contains reason if {
    reason := "viewer cannot call tools"
    input.role == "viewer"
    input.method == "POST"
    input.path == "/mcp"
    # Check if it's a tools/call request
    input.tool != ""
}

# RBAC: user can only call read-only tools (no destructive operations)
deny contains reason if {
    reason := sprintf("user role cannot call tool %s", [input.tool])
    input.role == "user"
    # Block write operations for user role
    is_write_tool(input.tool)
}

# Rule: transfer_stock requires admin role
deny contains reason if {
    reason := "transfer_stock requires admin role"
    endswith(input.tool, ".transfer_stock")
    input.role != "admin"
}

# Also match underscore notation (e.g., erp_transfer_stock)
deny contains reason if {
    reason := "transfer_stock requires admin role"
    endswith(input.tool, "_transfer_stock")
    input.role != "admin"
}

# Helper: check if tool is a write operation
is_write_tool(tool) if {
    endswith(tool, ".create_stock_entry")
}

is_write_tool(tool) if {
    endswith(tool, "_create_stock_entry")
}

is_write_tool(tool) if {
    endswith(tool, ".transfer_stock")
}

is_write_tool(tool) if {
    endswith(tool, "_transfer_stock")
}

is_write_tool(tool) if {
    endswith(tool, ".create_order")
}

is_write_tool(tool) if {
    endswith(tool, "_create_order")
}

# Sensitive tools requiring specific user whitelist
sensitive_tools := {"erp.transfer_stock", "hr.delete_employee", "hr.update_salary"}

# RBAC: sensitive tools require whitelisted user
deny contains reason if {
    reason := sprintf("user %s is not authorized for sensitive tool %s", [input.user_id, input.tool])
    input.tool in sensitive_tools
    # Check whitelist - Data API wraps values in {"value": {...}}
    not user_in_whitelist(input.user_id, input.tool)
}

# Helper: check if user is in whitelist
# Note: whitelist data is stored at data.mcp_config.user_whitelists (outside mcp.auth namespace)
user_in_whitelist(user_id, tool) if {
    some i
    data.mcp_config.user_whitelists[tool][i] == user_id
}
