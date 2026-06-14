#!/usr/bin/env python3
"""
Post-Compact Context Restoration Hook

Fires after compaction (SessionStart with source="compact"|"resume")
to restore context from pre-compact state.
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path
import hashlib

CYAN = "\033[0;36m"
GREEN = "\033[0;32m"
YELLOW = "\033[0;33m"
NC = "\033[0m"


def get_session_dir() -> Path:
    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", "")
    if not project_dir:
        return Path.home() / ".claude" / "sessions" / "default"
    project_hash = hashlib.md5(project_dir.encode()).hexdigest()[:8]
    session_dir = Path.home() / ".claude" / "sessions" / project_hash
    session_dir.mkdir(parents=True, exist_ok=True)
    return session_dir


def find_active_plan(project_dir: str) -> dict | None:
    plans_dir = Path(project_dir) / "quality_reports" / "plans"
    if not plans_dir.exists():
        return None
    plan_files = sorted(plans_dir.glob("*.md"), key=lambda f: f.stat().st_mtime, reverse=True)
    if not plan_files:
        return None
    latest = plan_files[0]
    content = latest.read_text()
    status = "unknown"
    if "COMPLETED" in content.upper():
        status = "completed"
    elif "APPROVED" in content.upper():
        status = "in_progress"
    elif "DRAFT" in content.upper():
        status = "draft"
    current_task = None
    for line in content.split("\n"):
        if "- [ ]" in line:
            current_task = line.replace("- [ ]", "").strip()
            break
    return {"plan_path": str(latest), "plan_name": latest.name, "status": status, "current_task": current_task}


def find_recent_session_log(project_dir: str) -> dict | None:
    logs_dir = Path(project_dir) / "quality_reports" / "session_logs"
    if not logs_dir.exists():
        return None
    log_files = sorted(logs_dir.glob("*.md"), key=lambda f: f.stat().st_mtime, reverse=True)
    if not log_files:
        return None
    return {"log_path": str(log_files[0]), "log_name": log_files[0].name}


def main() -> int:
    try:
        hook_input = json.load(sys.stdin)
    except (json.JSONDecodeError, IOError):
        hook_input = {}

    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", "")
    if not project_dir:
        return 0

    state_file = get_session_dir() / "pre-compact-state.json"
    pre_state = None
    if state_file.exists():
        try:
            pre_state = json.loads(state_file.read_text())
            state_file.unlink()
        except (json.JSONDecodeError, IOError):
            pass

    plan_info = find_active_plan(project_dir)
    session_log = find_recent_session_log(project_dir)

    lines = [f"\n{CYAN}[Context Restored After Compaction]{NC}", ""]

    if pre_state:
        lines.append(f"{GREEN}Pre-Compaction State:{NC}")
        if pre_state.get("plan_path"):
            lines.append(f"  Plan: {Path(pre_state['plan_path']).name}")
        if pre_state.get("current_task"):
            lines.append(f"  Task: {pre_state['current_task']}")
        if pre_state.get("decisions"):
            lines.append("  Recent decisions:")
            for d in pre_state["decisions"][-3:]:
                lines.append(f"    - {d[:80]}")
        lines.append("")

    if plan_info:
        lines.append(f"{GREEN}Active Plan:{NC}")
        lines.append(f"  File: {plan_info['plan_name']}")
        lines.append(f"  Status: {plan_info['status']}")
        if plan_info.get("current_task"):
            lines.append(f"  Next task: {plan_info['current_task']}")
        lines.append("")

    if session_log:
        lines.append(f"{GREEN}Session Log:{NC} {session_log['log_name']}")
        lines.append("")

    lines.append(f"{YELLOW}Recovery:{NC}")
    lines.append("  1. Read active plan for current objectives")
    lines.append("  2. Check git status/diff for uncommitted changes")
    lines.append("  3. Continue from where you left off")
    lines.append("")

    print("\n".join(lines))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        sys.exit(0)
