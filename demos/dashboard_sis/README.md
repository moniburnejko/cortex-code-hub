# dashboard_sis

insurance renewal analytics dashboard built autonomously by cortex code cli on streamlit in snowflake (SiS).

end-to-end demonstration: infrastructure setup, data load, streamlit app build, and governance audit loop across four sessions.

## contents

| file / folder | description |
|---|---|
| [AGENTS.md](AGENTS.md) | project spec - single source of truth for the agent |
| [prompts.md](prompts.md) | 4-phase session prompts with acceptance checkpoints |
| [skills/](skills/) | 7 skills invoked by the agent |
| [sql/](sql/) | DDL for source tables, domain tables, stage, and logging infrastructure |
| [semantic_model.yaml](semantic_model.yaml) | Cortex Analyst semantic model for the renewal domain |
| [reports/](reports/) | session reports from each cortex code cli run |

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
