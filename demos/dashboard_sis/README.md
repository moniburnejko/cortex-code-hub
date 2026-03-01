# dashboard_sis

insurance renewal analytics dashboard built autonomously by cortex code cli on streamlit in snowflake (SiS).

end-to-end demonstration: infrastructure setup, data load, streamlit app build, and governance audit loop across four sessions.

## contents

| file | description |
|---|---|
| [AGENTS.md](AGENTS.md) | project spec - single source of truth for the agent |
| [prompts.md](prompts.md) | 4-phase session prompts with acceptance checkpoints |
| [final_report.md](final_report.md) | acceptance report covering all four phases |

full source - skills, sql, reports, dashboard code: [moniburnejko/cortex-sis-dashboard](https://github.com/moniburnejko/cortex-sis-dashboard)

## key findings

- production-ready for repeatable, well-described tasks
- agent efficiency is a direct function of AGENTS.md quality
- skills encode platform constraints (SiS warehouse runtime) that prevent redeploy cycles
- credential sanitization via pre-commit hook is required to safely version a project with real Snowflake object names
- the pre-flight gate in AGENTS.md (session start check) eliminates silent context failures

## related

- [concepts/](../concepts/) - skills, context injection, AGENTS.md structure
- [guides/](../guides/) - how to write AGENTS.md, create skills, write session prompts
- [use_cases/](../use_cases/) - SiS dashboard builds, multi-phase project workflows
