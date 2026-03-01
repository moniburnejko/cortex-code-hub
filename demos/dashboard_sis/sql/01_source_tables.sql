-- source table DDL
-- DDL rule, no exceptions: use CREATE OR ALTER TABLE for all tables.
-- never CREATE OR REPLACE TABLE, that drops and recreates, destroying existing data.
-- substitute {database} and {schema} from AGENTS.md environment table before running.

CREATE OR ALTER TABLE {database}.{schema}.FACT_RENEWAL (
    policy_id        VARCHAR(10),
    client_id        VARCHAR(10),
    renewal_date     DATE,
    region           VARCHAR(2),
    segment          VARCHAR(30),
    product_variant  VARCHAR(20),
    channel          VARCHAR(20),
    agent_id         VARCHAR(10),
    renewal_outcome  VARCHAR(20),
    is_quoted        NUMBER(1),
    is_bound         NUMBER(1),
    is_renewed       NUMBER(1),
    quote_tta        FLOAT,
    target_tta_hours FLOAT
);

CREATE OR ALTER TABLE {database}.{schema}.FACT_PREMIUM_EVENT (
    pricing_event_id VARCHAR(30),
    policy_id        VARCHAR(10),
    client_id        VARCHAR(10),
    renewal_date     DATE,
    event_ts         TIMESTAMP_NTZ,
    event_seq        NUMBER(2),
    event_type       VARCHAR(20),
    is_final_offer   NUMBER(1),
    source_system    VARCHAR(30),
    region           VARCHAR(2),
    segment          VARCHAR(30),
    channel          VARCHAR(20),
    agent_id         VARCHAR(10),
    expiring_premium FLOAT,
    offered_premium  FLOAT,
    discount_amt     FLOAT,
    discount_pct     FLOAT,
    discount_reason  VARCHAR(100),
    renewal_outcome  VARCHAR(20)
);

CREATE OR ALTER TABLE {database}.{schema}.DIM_POLICY (
    policy_id              VARCHAR(10),
    client_id              VARCHAR(10),
    segment                VARCHAR(30),
    region                 VARCHAR(2),
    product_variant        VARCHAR(20),
    date_inception         DATE,
    date_last_renewal      DATE,
    date_next_renewal      DATE,
    sum_insured_band       VARCHAR(10),
    risk_tier              VARCHAR(15),
    payment_frequency      VARCHAR(15),
    auto_renewal_flag      NUMBER(1),
    annual_aggregate_limit FLOAT,
    per_occurrence_limit   FLOAT,
    policy_excess          FLOAT
);
