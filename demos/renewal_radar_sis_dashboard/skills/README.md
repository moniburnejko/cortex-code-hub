# skills - renewal radar sis dashboard

to use these skills in a project, copy the skill directories into `.cortex/skills/` at the project root and commit to the repo. `check-local-environment` is personal - install it at `~/.snowflake/cortex/skills/check-local-environment/` instead.

## why these skills exist alongside the global developing-with-streamlit skill

the Snowflake global skill library includes `developing-with-streamlit`, a routing skill covering general Streamlit development across all deployment targets. that skill is useful for local apps and SPCS container runtime deployments. this project uses **SiS warehouse runtime**, which is a different environment with a different constraint set.

**the global skill and this project's skills are complementary, not competing** - but they conflict on several specific points. when both are active, the project skills take priority for anything related to warehouse runtime. see `AGENTS.md` section "global skill override" for the full conflict map.

key differences that make project-specific skills necessary:

| area | global developing-with-streamlit | these project skills |
|---|---|---|
| deployment target | SPCS container runtime (`compute_pool`, `runtime_name`) | SiS warehouse runtime (no compute_pool) |
| `snowflake.yml` artifacts | required - list all files | forbidden - causes deployment errors in warehouse runtime |
| `@st.fragment` | recommended for performance | forbidden - unreliable in warehouse runtime |
| `st.rerun()` | shown as valid pattern | forbidden - causes infinite loops and connection resets in warehouse runtime |
| Snowflake connection | `st.connection("snowflake")` | `get_active_session()` - required in SiS |
| dependencies | `pyproject.toml` + pip | `environment.yml` + Snowflake Anaconda channel only |
| Streamlit version | pinnable via pyproject.toml | pinned via `streamlit=1.52.*` in environment.yml |
| pre-deploy validation | none | mandatory: `build-dashboard` scans for forbidden patterns before every deploy |

the global skill covers the "how to write Streamlit" layer well. these project skills cover the "how to deploy and validate for SiS warehouse runtime" layer that the global skill does not address.

---

## skills in this folder

### `check-local-environment` - user-level

verifies local tooling before starting any Snowflake or Cortex Code CLI session. checks snow CLI version, `config.toml` permissions (must be `0600`), lists available named connection profiles, runs `snow connection test`, and confirms Python is available (needed by `$ build-dashboard`'s `py_compile` step). run once at the start of each session.

```
$ check-local-environment
```

### `check-snowflake-context` - project

verifies the active Snowflake session matches the expected environment from AGENTS.md: role, warehouse, database, account. if any value is wrong, sets it explicitly via `USE ROLE / USE WAREHOUSE / USE DATABASE`. also checks whether key schema objects exist (stage, audit log) without creating anything. run after `$ check-local-environment`, before phase 1.

```
$ check-snowflake-context
```

### `prepare-data` - project

validates local csv files and loads them into Snowflake. two phases: (1) validation - file exists, encoding, header row, column count, row count, no oversized rows; (2) load - gzip, PUT, COPY INTO, row count verification. stops on validation errors and asks the user before proceeding. reads file metadata (delimiter, expected row count) from AGENTS.md.

```
$ prepare-data
```

### `sis-streamlit` - project. master for all SiS work

project-level skill for SiS warehouse runtime (streamlit 1.52.*) - supersedes the global `developing-with-streamlit` skill for all Streamlit work in this project.

routes to four sub-skills:
- `sis-patterns` - connection, caching, widgets, layout, session state patterns for SiS warehouse runtime
- `build-dashboard` - API constraints, scaffold, and pre-deploy scan
- `brand-identity` - visual identity, chart type rules, colors, language conventions
- `deploy-and-verify` - deployment workflow and phase acceptance checks

```
$ sis-streamlit
```

#### `sis-streamlit/skills/sis-patterns`

covers Streamlit patterns specific to SiS warehouse runtime: `get_active_session()` connection, `@st.cache_data`, widget constraints, layout patterns, and session state. load before writing any Streamlit code.

#### `sis-streamlit/skills/build-dashboard` - three modes

the central quality gate for SiS development.

**discovery mode** - called without arguments, before writing any code. loads the SiS API constraint table into context so the agent uses correct APIs from the start.

**scaffold mode** - called with `scaffold` argument. generates `dashboard.py` at project root from a parameterized template and creates `environment.yml` at project root with `streamlit=1.52.*`. also loads `brand-identity` automatically.

**scan mode** - called with a file path. scans the Python file for forbidden patterns (`st.rerun()`, `st.fragment`, `style.applymap()`, `horizontal=True`, date casting issues, NULL guards, etc.), runs `py_compile`, validates style rules, and verifies `snowflake.yml` exists.

loaded via `$ sis-streamlit` or `$ sis-dashboard`.

#### `sis-streamlit/skills/brand-identity`

defines the visual identity, chart type rules, style defaults, and language conventions for the dashboard. contains: color palette (primary #1565C0 / accent #FFA726 / status colors), chart type selection rules (which Altair mark for which use case), axis formatting defaults (percentage format, labelAngle, legend orientation), heatmap and status color functions (`.map()` implementations), and language conventions (KPI label casing, button text, filter labels). loaded before generating any Streamlit page content.

loaded via `$ sis-streamlit` or `$ sis-dashboard`.

#### `sis-streamlit/skills/deploy-and-verify` - two modes

**deploy mode** - end-to-end deployment workflow. runs `build-dashboard` scan internally, verifies `snowflake.yml` values match AGENTS.md environment, confirms active role, runs `snow streamlit deploy --replace`, and confirms the app loads.

**verify mode** - runs SQL acceptance checks for phase 1 (infrastructure), phase 2 (dashboard), or phase 3 (write-back). produces a pass/fail report with phase summary.

loaded via `$ sis-streamlit` or `$ sis-dashboard`.

### `sis-dashboard` - project router

master entry point that routes to the correct sub-skill based on user intent. maps natural language requests ("deploy the app", "check my data", "run acceptance checks") to the appropriate skill invocation. use this when the intent is ambiguous or as a general starting point.

```
$ sis-dashboard
```

## workflow

invoke via `$ sis-dashboard` (routes all steps) or `$ sis-streamlit` (Streamlit steps only).

```
session start
  |- $ check-local-environment
  |- $ check-snowflake-context     - Snowflake-side: role, warehouse, schema, objects

before generating Streamlit code (via $ sis-streamlit)
  |- build-dashboard               - load SiS API constraint table into context
  |- brand-identity                - load visual identity, chart type rules, colors, language

phase 1: data loading
  |- $ prepare-data                - validate, PUT, COPY INTO, verify row counts
  |- deploy-and-verify phase-1     - infrastructure acceptance checks

phase 2: deploy (via $ sis-streamlit)
  |- build-dashboard scaffold      - generate dashboard.py + environment.yml
  |- build-dashboard <file>        - pre-deploy scan + style validation
  |- deploy-and-verify deploy      - deploy to SiS
  |- deploy-and-verify phase-2     - dashboard acceptance checks

phase 3: write-back
  |- deploy-and-verify phase-3     - write-back acceptance checks

final
  |- deploy-and-verify all         - full sweep, produces final pass/fail report
```
