---
name: check-local-environment
description: "verify local prerequisites before starting a Snowflake or Cortex Code CLI session: snow CLI, config.toml permissions, connection test, Python, and available connection profiles. trigger when the user asks to check local setup, verify prerequisites, or confirm the environment is ready before starting work. do NOT use for Snowflake-side context (role, warehouse, database) - that belongs in a separate session check."
---

## steps

1. check snow CLI is installed: `snow --version` - note the version.
   if not found: stop and tell the user to install snow CLI. install guide: https://docs.snowflake.com/en/developer-guide/snowflake-cli/installation/installation

2. check config.toml permissions: `stat ~/.snowflake/config.toml` - must show `0600`.
   if not `0600`: run `chmod 0600 ~/.snowflake/config.toml`, then re-run stat to confirm.
   if the file does not exist: warn the user - snow CLI requires a config.toml with at least one named connection. guide: https://docs.snowflake.com/en/developer-guide/snowflake-cli/connecting/specify-credentials
   note: on Windows, stat output differs - check that the file is not world-readable.

3. list available connection profiles: `snow connection list` - note the names and which one is marked as default.
   if no connections are listed: stop and tell the user to configure at least one connection in config.toml (see step 2 guide link).

4. test the default connection: `snow connection test` - must return 'Connection is valid'.
   if it fails: show the full error and stop. do NOT attempt to fix connection strings automatically.
   common causes: wrong account identifier, expired password, IP allowlist, missing MFA token. tell the user to check their config.toml credentials.

5. check Python is available: `python --version` - note the version.
   if not found: try `python3 --version`.
   Python is required for `python -m py_compile` used by `build-dashboard` (scan mode).
   if neither found: mark as WARN (not blocking), but note that pre-deploy syntax checks will be skipped.

6. report summary:
   - snow CLI version
   - config.toml permissions (0600: yes/no)
   - available connection profiles (names, default)
   - connection test result (valid / error message)
   - Python version (or 'not found')

## success criteria

- `snow --version` returns a version string
- `~/.snowflake/config.toml` exists with permissions 0600
- at least one connection profile is listed
- `snow connection test` returns 'Connection is valid'
- `python --version` or `python3 --version` returns a version string
