-- stage creation (idempotent, safe to re-run)
-- substitute {database}, {schema}, and {stage} from AGENTS.md environment table before running.

CREATE STAGE IF NOT EXISTS {database}.{schema}.{stage};

-- confirm after creation:
-- SHOW STAGES IN SCHEMA {database}.{schema};
-- expect: 1 row with name STAGE_RAW_CSV
