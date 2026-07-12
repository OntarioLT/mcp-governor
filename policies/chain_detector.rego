package mcp.chain_detector

default allow = false

allow if {
    count(deny) == 0
}

# === File Access Rules ===

# Rule 1: /etc/passwd read then network send
deny contains reason if {
    reason := "dangerous: file_read(/etc/passwd) then network_send"
    input.history[_].tool == "file_read"
    input.history[_].path == "/etc/passwd"
    input.current_tool == "network_send"
}

# Rule 2: Any sensitive file read then network send
deny contains reason if {
    sensitive_paths := {"/etc/shadow", "/etc/passwd", "/etc/sudoers", "/root/.ssh/authorized_keys"}
    reason := "dangerous: sensitive file read then network exfiltration"
    some i
    input.history[i].tool == "file_read"
    sensitive_paths[input.history[i].path]
    input.current_tool == "network_send"
}

# Rule 3: file_write to sensitive paths
deny contains reason if {
    sensitive_write := {"/etc/passwd", "/etc/shadow", "/root/.bashrc", "/etc/crontab"}
    reason := "dangerous: write to system critical path"
    some i
    input.history[i].tool == "file_write"
    sensitive_write[input.history[i].path]
}

# === Data Exfiltration Rules ===

# Rule 4: db_query -> file_write -> network_send (classic exfiltration)
deny contains reason if {
    reason := "dangerous: database_query → file_write → network_send"
    count(input.history) >= 2
    input.history[count(input.history) - 2].tool == "database_query"
    input.history[count(input.history) - 1].tool == "file_write"
    input.current_tool == "network_send"
}

# Rule 5: file_read -> network_send (data exfiltration)
deny contains reason if {
    reason := "dangerous: file_read then network_send (data exfiltration)"
    count(input.history) >= 1
    input.history[count(input.history) - 1].tool == "file_read"
    input.current_tool == "network_send"
}

# Rule 6: database_query -> network_send (direct exfiltration)
deny contains reason if {
    reason := "dangerous: database_query → network_send"
    count(input.history) >= 1
    input.history[count(input.history) - 1].tool == "database_query"
    input.current_tool == "network_send"
}

# Rule 7: Multiple file reads followed by network send (batch exfiltration)
deny contains reason if {
    reason := "dangerous: multiple file reads then network send"
    read_count := count([i | input.history[i].tool == "file_read"])
    read_count >= 3
    input.current_tool == "network_send"
}

# === Dangerous Tool Sequences ===

# Rule 8: shell_exec after file_read (potential injection)
deny contains reason if {
    reason := "dangerous: file_read then shell_exec"
    count(input.history) >= 1
    input.history[count(input.history) - 1].tool == "file_read"
    input.current_tool == "shell_exec"
}

# Rule 9: shell_exec with network_send (reverse shell pattern)
deny contains reason if {
    reason := "dangerous: shell_exec then network_send (reverse shell pattern)"
    count(input.history) >= 1
    input.history[count(input.history) - 1].tool == "shell_exec"
    input.current_tool == "network_send"
}

# Rule 10: database_query -> file_write (data dump)
deny contains reason if {
    reason := "dangerous: database_query → file_write (data dump)"
    count(input.history) >= 1
    input.history[count(input.history) - 1].tool == "database_query"
    input.current_tool == "file_write"
}

# === Role-Based Access Rules ===

# Rule 11: Dangerous tools require admin role
deny contains reason if {
    dangerous_tools := {"shell_exec", "rm_rf", "modify_firewall", "shutdown", "reboot", "sudo"}
    reason := sprintf("dangerous tool %s requires admin", [input.current_tool])
    input.current_tool in dangerous_tools
    input.role != "admin"
}

# Rule 12: Network tools require admin for write operations
deny contains reason if {
    reason := sprintf("network write tool %s requires admin", [input.current_tool])
    input.current_tool in {"network_send", "network_upload", "email_send"}
    input.role != "admin"
}

# Rule 13: Database write operations require admin
deny contains reason if {
    write_tools := {"database_write", "database_delete", "database_drop", "database_alter"}
    reason := sprintf("database write tool %s requires admin", [input.current_tool])
    input.current_tool in write_tools
    input.role != "admin"
}

# === Workspace Isolation Rules ===

# Rule 14: Cross-workspace file access
deny contains reason if {
    reason := sprintf("cross-workspace access: %s from %s to %s", [input.current_tool, input.workspace, input.target_workspace])
    input.workspace != ""
    input.target_workspace != ""
    input.workspace != input.target_workspace
    input.role != "admin"
}

# Rule 15: Access to other user's workspace
deny contains reason if {
    reason := sprintf("unauthorized workspace access: %s", [input.current_tool])
    input.target_workspace != ""
    input.target_workspace != input.workspace
    input.role == "viewer"
}

# === Rate Abuse Rules ===

# Rule 16: High frequency tool calls (>5 calls in <60s)
deny contains reason if {
    reason := sprintf("rate abuse: %d calls in %d seconds", [input.call_count, input.window_seconds])
    input.call_count > 5
    input.window_seconds < 60
}

# Rule 17: Extreme rate abuse (>20 calls in <60s)
deny contains reason if {
    reason := sprintf("extreme rate abuse: %d calls in %d seconds", [input.call_count, input.window_seconds])
    input.call_count > 20
    input.window_seconds < 60
}

# === Prompt Injection Patterns ===

# Rule 18: System prompt override attempt
deny contains reason if {
    reason := "prompt injection: system prompt override attempt"
    input.current_tool in {"shell_exec", "file_write"}
    contains(input.text, "ignore previous")
}

# Rule 19: Role escalation attempt
deny contains reason if {
    reason := "prompt injection: role escalation attempt"
    contains(input.text, "you are now")
    input.role != "admin"
}

# Rule 20: Instruction bypass attempt
deny contains reason if {
    reason := "prompt injection: instruction bypass attempt"
    bypass_patterns := {"ignore all", "disregard", "forget your instructions", "new instructions"}
    some pattern in bypass_patterns
    contains(lower(input.text), pattern)
}

# === Credential/Secret Rules ===

# Rule 21: Credential file access
deny contains reason if {
    credential_paths := {"/etc/shadow", ".env", "credentials.json", "secrets.yaml", ".ssh/id_rsa"}
    reason := "dangerous: credential file access"
    some i
    input.history[i].tool == "file_read"
    credential_paths[input.history[i].path]
}

# Rule 22: Network send with credential content
deny contains reason if {
    reason := "dangerous: possible credential exfiltration via network"
    input.current_tool == "network_send"
    contains(input.text, "password")
    contains(input.text, "secret")
}

# === Privilege Escalation Rules ===

# Rule 23: sudo usage without admin
deny contains reason if {
    reason := "privilege escalation: sudo requires admin"
    input.current_tool == "shell_exec"
    contains(input.text, "sudo")
    input.role != "admin"
}

# Rule 24: chmod/chown operations
deny contains reason if {
    chmod_tools := {"chmod", "chown", "chgrp"}
    reason := sprintf("privilege escalation: %s requires admin", [input.current_tool])
    input.current_tool in chmod_tools
    input.role != "admin"
}

# === Resource Abuse Rules ===

# Rule 25: Fork bomb pattern
deny contains reason if {
    reason := "resource abuse: potential fork bomb"
    input.current_tool == "shell_exec"
    contains(input.text, ":(){ :|:& };:")
}

# Rule 26: Disk fill pattern
deny contains reason if {
    reason := "resource abuse: potential disk fill"
    input.current_tool == "shell_exec"
    contains(input.text, "dd if=/dev/zero")
}

# Rule 27: Crypto mining detection
deny contains reason if {
    reason := "resource abuse: crypto mining attempt"
    mining_patterns := {"xmrig", "minerd", "cpuminer", "stratum+tcp"}
    some pattern in mining_patterns
    contains(input.text, pattern)
}

# === Network Abuse Rules ===

# Rule 28: Reverse shell patterns
deny contains reason if {
    reason := "dangerous: reverse shell pattern detected"
    shell_patterns := {"bash -i", "/dev/tcp/", "nc -e", "ncat -e", "mkfifo"}
    some pattern in shell_patterns
    contains(input.text, pattern)
    input.current_tool in {"shell_exec", "network_send"}
}

# Rule 29: Port scanning
deny contains reason if {
    reason := "dangerous: port scanning attempt"
    input.current_tool == "shell_exec"
    contains(input.text, "nmap")
}

# Rule 30: DNS exfiltration
deny contains reason if {
    reason := "dangerous: DNS exfiltration attempt"
    input.current_tool == "shell_exec"
    contains(input.text, "dig")
    contains(input.text, "TXT")
}
