# renewal radar sis dashboard

insurance renewal analytics dashboard built autonomously by cortex code cli.

end-to-end demonstration of agent-driven development: infrastructure setup, streamlit app, and governance audit loop.

## what's in here

- [AGENTS.md](AGENTS.md) - project specification for the cortex code cli agent
- [prompts.md](prompts.md) - session prompts: 4 phases with checkpoints
- [skills/](skills/) - 7 reusable skills invoked by the agent

## key findings

- production-ready for repeatable, well-described tasks
- agent efficiency is a direct function of AGENTS.md quality
- skills encode platform constraints (SiS warehouse runtime) that prevent redeploy cycles