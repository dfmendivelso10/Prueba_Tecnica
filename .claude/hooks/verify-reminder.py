#!/usr/bin/env python3
"""
Verification Reminder Hook

Non-blocking reminder after Write/Edit on analysis scripts
to remind about running the script before marking done.
"""

from __future__ import annotations

import json
import os
import sys
import time
from pathlib import Path
import hashlib

CYAN = "\033[0;36m"
GREEN = "\033[0;32m"
NC = "\033[0m"

VERIFY_EXTENSIONS = {
    ".py": "run with: python",
    ".R": "run with: Rscript",
    ".do": "run with: stata -b do",
}

SKIP_DIRS = ["/docs/", "/templates/", "/quality_reports/", "/.claude/", "explorations/ARCHIVE/"]


def get_session_dir() -> Path:
    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", "")
    if not project_dir:
        return Path.home() / ".claude" / "sessions" / "default"
    project_hash = hashlib.md5(project_dir.encode()).hexdigest()[:8]
    session_dir = Path.home() / ".claude" / "sessions" / project_hash
    session_dir.mkdir(parents=True, exist_ok=True)
    return session_dir


def main() -> int:
    try:
        hook_input = json.load(sys.stdin)
    except (json.JSONDecodeError, IOError):
        return 0

    file_path = hook_input.get("tool_input", {}).get("file_path", "")
    if not file_path:
        return 0

    path = Path(file_path)

    if path.suffix.lower() not in VERIFY_EXTENSIONS:
        return 0
    for skip_dir in SKIP_DIRS:
        if skip_dir in file_path:
            return 0

    cache_file = get_session_dir() / "verify-reminder-cache.json"
    now = time.time()
    try:
        cache = json.loads(cache_file.read_text()) if cache_file.exists() else {}
    except (json.JSONDecodeError, IOError):
        cache = {}

    if now - cache.get(file_path, 0) < 60:
        return 0

    cache[file_path] = now
    cache = {k: v for k, v in cache.items() if now - v < 300}
    try:
        cache_file.write_text(json.dumps(cache))
    except IOError:
        pass

    action = VERIFY_EXTENSIONS[path.suffix.lower()]
    print(f"\n{CYAN}Reminder:{NC} {path.name} → {GREEN}{action} {path.name}{NC}\n")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        sys.exit(0)
