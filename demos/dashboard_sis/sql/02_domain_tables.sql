-- domain table DDL
-- this is the only domain table to create. logging infrastructure is in 04_logging_infrastructure.sql.
-- DDL rule, no exceptions: use CREATE OR ALTER TABLE.
-- substitute {database} and {schema} from AGENTS.md environment table before running.

CREATE OR ALTER TABLE {database}.{schema}.RENEWAL_FLAGS (
    flag_id        VARCHAR(40)   DEFAULT UUID_STRING(),
    flagged_at     TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    flagged_by     VARCHAR(100),          -- populated explicitly by app; do NOT rely on DEFAULT CURRENT_USER() in SiS
    scope          VARCHAR(50),          -- any combination of REGION/SEGMENT/CHANNEL joined by '_'
    scope_region   VARCHAR(50),          -- NULL when not scoped to a region
    scope_segment  VARCHAR(50),          -- NULL when not scoped to a segment
    scope_channel  VARCHAR(50),          -- NULL when not scoped to a channel
    flag_reason    VARCHAR(200),
    status         VARCHAR(20)   DEFAULT 'OPEN',
    reviewed_by    VARCHAR(100),
    reviewed_at    TIMESTAMP_NTZ,
    notes          VARCHAR(500),
    PRIMARY KEY (flag_id)
);
