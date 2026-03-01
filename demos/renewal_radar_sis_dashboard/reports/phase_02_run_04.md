# phase 2 execution report: renewal radar sis dashboard

**date:** 2026-03-01
**session:** cortex code cli, prompt 3 (dashboard build) - 1 agent session
**environment:** CORTEX_DB.CORTEX_SCHEMA, role CORTEX_ADMIN, warehouse CORTEX_WH
**model:** claude-sonnet-4-5
**final outcome:** phase 2 complete - dashboard deployed, runtime error found and fixed, redeployed; awaiting render confirmation

**context:** this run follows phase_02_run_03.md. governance improvements and spec corrections
from run_03 post-run review were already applied (environment.yml restored, SQL parameterization
check in build-dashboard, 7 spec fixes in AGENTS.md).

---

## 1. what phase 2 covers

phase 2 builds and deploys the 3-page streamlit in snowflake dashboard.
it is a single prompt (prompt 3) with a checkpoint before phase 3 begins.

- **prompt 3 (dashboard build and deploy):**
  - enter `/plan` before pasting the prompt (required per prompts.md)
  - load SiS patterns via `$ sis-streamlit` before planning
  - scaffold structure via `$ sis-streamlit` -> `build-dashboard` (no args)
  - load visual identity via `$ sis-streamlit` -> `brand-identity`
  - generate `dashboard.py` with 3 pages per AGENTS.md specification
  - run pre-deploy scan via `$ sis-streamlit` -> `build-dashboard dashboard.py`
  - deploy via `$ sis-streamlit` -> `deploy-and-verify`
  - stop after showing the app url and wait for confirmation

---

## 2. prompts used

### prompt 3

```
phase 1 is complete. all infrastructure and data are in place.
build and deploy the dashboard.
stop after showing the app url and wait for my confirmation
that all 3 pages render correctly.
```

### correction (after runtime error)

after first deployment, a runtime error was found. the following debugging instruction was given:

```
runtime error after deploy:
TypeError: 'filter/where' expected Column or str as SQL expression,
got: <class 'pandas.core.series.Series'>

scan the entire file for all occurrences of the same error class
before fixing. fix all occurrences at once, then redeploy.
```

---

## 3. what AGENTS.md specifies for phase 2

note: this section reflects AGENTS.md after all post-run-03 spec corrections were applied,
including environment.yml restoration and 7 dashboard spec fixes.

### mandatory skills for phase 2

| skill | scope | when | constraint |
|---|---|---|---|
| `$ check-local-environment` | project | session start | do NOT proceed without verifying snow CLI, connections.toml, Python |
| `$ check-snowflake-context` | project | session start | do NOT proceed without verifying role, warehouse, database, schema |
| `$ sis-streamlit` | project | before any Streamlit planning or code | do NOT write Streamlit code without loading SiS patterns first |
| `$ sis-streamlit` -> `build-dashboard` (no args) | project | before writing code | do NOT write dashboard.py without scaffold output |
| `$ sis-streamlit` -> `brand-identity` | project | before writing code | do NOT use colors or fonts without loading brand identity |
| `$ sis-streamlit` -> `build-dashboard` (with file) | project | before every deploy | do NOT deploy without pre-deploy scan passing |
| `$ sis-streamlit` -> `deploy-and-verify` | project | deploy | do NOT run snow streamlit deploy directly |

### phase 2 done criteria (from AGENTS.md)

```
snow streamlit list -> {app_name} must appear with non-empty user_packages (confirms environment.yml uploaded)
python3 -m py_compile dashboard.py -> exit code 0
app URL opens, all 3 pages render with data (manual verification)
```

---

## 4. execution trace

### memory check and context verification

the agent checked memory and found phase 1 complete (8/8 acceptance checks passed, all 3
tables loaded). it verified the current state directly via `SNOWFLAKE_SQL_EXECUTE`:

| check | result |
|---|---|
| LOG_AUDIT_EVENT procedure | exists, created 2026-02-28 12:54:35 |
| FACT_RENEWAL row count | 50,000 |
| DIM_POLICY row count | 36,298 |
| FACT_PREMIUM_EVENT row count | 94,642 |
| domain tables (RENEWAL_FLAGS etc.) | 3 tables confirmed |

note: this context verification was not done via `$ check-local-environment` and
`$ check-snowflake-context` skills - see deviation 1.

### plan mode

the agent proposed the following build plan:

1. invoke `$ sis-streamlit` -> load sis-patterns, build-dashboard, brand-identity sub-skills
2. create environment.yml (Streamlit 1.52.*, pandas, altair from Snowflake Anaconda channel)
3. create snowflake.yml (app manifest, no forbidden fields)
4. create dashboard.py (574 lines, 3 pages per AGENTS.md spec)
5. run pre-deploy scan via `$ sis-streamlit build-dashboard` (listed correctly as skill)
6. deploy via `$ sis-streamlit deploy-and-verify phase-2` (listed correctly as skill)
7. stop and show app URL

the plan correctly specified skill-based scan and deploy. execution did not follow - see deviation 2.

### execution

**skills loaded:**
- `$ sis-streamlit` - invoked correctly
- sub-skills read: sis-patterns (202 lines), brand-identity (166 lines), build-dashboard (263 lines)

note: build-dashboard was 263 lines (vs. 220 lines in run_03 session 1), confirming the post-run-03
SQL parameterization check was already in the skill file.

**files created:**

| file | lines | location | result |
|---|---|---|---|
| environment.yml | 8 | project root | correct - no fix needed |
| snowflake.yml | 7 | project root | correct format (entities structure) - no fix needed |
| dashboard.py | 574 | project root | written, syntax check passed |

**pre-deploy scan (direct bash commands):**

- `grep -n "st."` - confirmed `st.set_page_config()` at line 9 (first st.* call)
- `grep` for st.fragment, st.experimental_rerun, PARSE_JSON, horizontal=True, applymap, st.rerun - all 0
- `python3 -m py_compile dashboard.py` - exit code 0
- `session.sql(f` check: NOT run (see deviation 3)

**first deployment:**
- command: `snow streamlit deploy --replace --connection pl_agents_team`
- result: success
- verified: `snow streamlit list --like "RENEWAL_RADAR"` - RENEWAL_RADAR present

**runtime error (found after testing the app):**

a runtime error occurred on the KPI Overview page:

```
TypeError: 'filter/where' expected Column or str as SQL expression,
got: <class 'pandas.core.series.Series'>
File "dashboard.py", line 113, in load_kpi_data
  df = _session.table(f"{DATABASE}.{SCHEMA}.FACT_RENEWAL").filter(
```

the agent read the full 574-line file and scanned for all occurrences of the error class:

```python
# line 113-115 (WRONG):
df = _session.table(f"{DATABASE}.{SCHEMA}.FACT_RENEWAL").filter(
    (pd.Series(regions).isin(regions)) if regions else True
).to_pandas()
```

only 1 occurrence found. root cause: `pd.Series(...).isin(...)` is a pandas expression,
not a Snowpark `Column`. Snowpark `.filter()` requires a Column expression. the pandas
filtering on lines 115-121 already handled all filter logic correctly, making the Snowpark
filter redundant.

**fix:**
- removed `.filter(...)` call entirely
- changed to: `df = _session.table(f"{DATABASE}.{SCHEMA}.FACT_RENEWAL").to_pandas()`
- verified: `pd.Series.*isin` grep - 0 matches; python3 -m py_compile - pass; forbidden patterns still 0

**redeployment:**
- command: `snow streamlit deploy --replace --connection pl_agents_team`
- result: success
- memory updated: `/memories/phase2_dashboard_build.md`

agent stopped and waited for confirmation.

---

## 5. skill compliance summary

| skill | supposed to run | actually invoked | result |
|---|---|---|---|
| `$ check-local-environment` | yes (session start) | no - context verified via SNOWFLAKE_SQL_EXECUTE | FAIL |
| `$ check-snowflake-context` | yes (session start) | no - context verified via SNOWFLAKE_SQL_EXECUTE | FAIL |
| `$ sis-streamlit` | yes (before planning/code) | yes, invoked | PASS |
| `$ sis-streamlit` -> `build-dashboard` (no args) | yes (before writing code) | yes, read sub-skill (263 lines) | PASS |
| `$ sis-streamlit` -> `brand-identity` | yes (before writing code) | yes, read sub-skill | PASS |
| `$ sis-streamlit` -> `build-dashboard` (with file) | yes (pre-deploy scan) | sub-skill read at plan time; scan ran as direct bash | PARTIAL - mechanism bypassed |
| `$ sis-streamlit` -> `deploy-and-verify` | yes (deploy) | sub-skill read at plan time; `snow streamlit deploy --replace` direct | PARTIAL - mechanism bypassed |

---

## 6. deviations and root causes

### deviation 1: session start gate not invoked

**what happened:** `$ check-local-environment` and `$ check-snowflake-context` were not invoked
before starting work. instead, the agent verified context directly via `SNOWFLAKE_SQL_EXECUTE`
calls to count rows in FACT_RENEWAL, DIM_POLICY, FACT_PREMIUM_EVENT, and check the procedure.

**root cause:** the agent appears to have treated the memory validation (checking phase 1 state)
as equivalent to the session start gate. memory validation is a different step - it confirms prior
progress, not local environment and Snowflake context readiness.

**consequence:** no practical impact in this run (context was correct). however, skills are
bypassed, which means local environment checks (Python version, snow CLI, connections.toml
permissions) were not verified.

**status:** open deviation.

### deviation 2: scan and deploy run as direct commands

**what happened:** the plan correctly specified skill-based scan and deploy, but both were
executed as direct bash commands.

**root cause:** same as all prior runs - skill files are markdown checklists, not executable
wrappers. the agent reads the skill and follows steps directly.

**consequence:** no SQL parameterization check run during scan (see deviation 3). deploy
skipped post-deploy user_packages verification specified in deploy-and-verify.

**status:** open pattern.

### deviation 3: SQL parameterization check not run during scan

**what happened:** the build-dashboard skill (263 lines) includes the mandatory
`session.sql(f` check added in the post-run-02 planning phase. the pre-deploy scan
in this session did NOT run this check - no `grep` for `session.sql(f` appears in the
execution trace.

**root cause:** consequence of deviation 2. the agent ran its own set of pattern checks
rather than following the build-dashboard scan checklist step by step. the basic forbidden
pattern checks were run, but the SQL parameterization check was not.

**consequence:** any SQL injection in this 574-line dashboard.py was not caught before deploy.
the runtime error that occurred (pandas.Series in Snowpark filter) is a different class of
error - a logic bug, not a SQL injection risk. no SQL injection was reported.

**status:** open pattern. SQL parameterization check is in the skill but not reliably executed
when scan runs as direct commands.

### deviation 4: runtime error not caught by pre-deploy scan

**what happened:** the deployed app threw a TypeError on the KPI Overview page
(`pandas.Series` passed to Snowpark `.filter()`). this was not caught by the pre-deploy scan.

**root cause:** the pre-deploy scan checks for forbidden API patterns (st.rerun, @st.fragment,
etc.) and SQL injection. it does not check for Snowpark API misuse such as passing pandas
objects to Snowpark methods. this is a logic error that only surfaces at runtime with live data.

**consequence:** an extra deploy cycle was required. the fix was straightforward and
correctly identified on the first attempt.

**status:** open class of bug. the build-dashboard scan checklist does not cover Snowpark
API correctness. could potentially be addressed by adding a pattern check for
`pd.Series.*\.isin` inside a `.filter()` call, but this may be too narrow.

---

## 7. root cause pattern (cross-phase)

| element | runs 02 and 03 | run 04 |
|---|---|---|
| session start gate | partial (context checked via direct commands) | missed entirely (replaced by memory validation + SNOWFLAKE_SQL_EXECUTE) |
| skill bypass (scan + deploy) | both sessions in both runs | same |
| SQL parameterization check | caught in run_03 session 2; missed in run_03 session 1 and run_02 | not run |
| runtime error before deploy | not applicable (logic bugs not caught by scan in any run) | TypeError pandas.Series in Snowpark filter - found and fixed post-deploy |
| files in correct location | wrong in run_02 (required mv); correct in run_03 | correct from the start |
| snowflake.yml fix cycles | 2 fix cycles in run_02; 0 in run_03 | 0 - correct format on first write |

---

## 8. file changes made within this run

no skill files or AGENTS.md were changed during or after this run. the runtime error fix
was applied only to dashboard.py.

**dashboard.py:**
- line 113-115: removed broken Snowpark `.filter(pd.Series(...).isin(...))` call
- replaced with: `df = _session.table(f"{DATABASE}.{SCHEMA}.FACT_RENEWAL").to_pandas()`
- all pandas-level filtering on subsequent lines was already correct and unchanged

---

## 9. executive summary

- **deployment status:** successful (after 1 fix cycle). app accessible at `CORTEX_DB.CORTEX_SCHEMA.RENEWAL_RADAR`; awaiting render confirmation.
- **runtime error:** TypeError - pandas.Series passed to Snowpark `.filter()` at line 113. found post-deploy, instruction to scan all occurrences before fixing was followed correctly. 1 occurrence found and removed. redeployed cleanly.
- **pre-deploy scan:** basic forbidden patterns checked (all 0). SQL parameterization check not run. runtime error class (Snowpark API misuse) not covered by any scan step.
- **session start gate:** not invoked. agent treated memory validation as equivalent to check-local-environment + check-snowflake-context, which it is not.
- **file placement:** environment.yml and snowflake.yml correctly at root from the start. no fix cycles needed for snowflake.yml format (definition_version 2 entities structure written correctly on first attempt).
- **skill bypass pattern:** sis-streamlit and all 3 sub-skills loaded correctly. scan and deploy ran as direct bash commands. same open pattern as all prior runs.
