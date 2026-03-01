-- logging infrastructure DDL
-- idempotent: safe to re-run. all statements use CREATE OR ALTER / CREATE IF NOT EXISTS.
-- exception: ADD SEARCH OPTIMIZATION, if those return 'column already has search optimization', skip them.
--
-- DDL rules:
--   tables: CREATE OR ALTER TABLE (never CREATE OR REPLACE TABLE)
--   views: CREATE OR REPLACE VIEW (safe, views hold no data; CREATE OR ALTER VIEW does not exist)
--   procedures: CREATE OR REPLACE PROCEDURE (intentional and correct)
--
-- substitute {database} and {schema} from AGENTS.md environment table before running.

-- APP_EVENTS event table
CREATE EVENT TABLE IF NOT EXISTS {database}.{schema}.APP_EVENTS
    DATA_RETENTION_TIME_IN_DAYS = 7
    MAX_DATA_EXTENSION_TIME_IN_DAYS = 7
    CHANGE_TRACKING = TRUE;

-- AUDIT_LOG table
CREATE OR ALTER TABLE {database}.{schema}.AUDIT_LOG (
    audit_id              NUMBER AUTOINCREMENT PRIMARY KEY,
    event_timestamp       TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP() NOT NULL,
    user_name             VARCHAR(256),
    role_name             VARCHAR(256),
    session_id            NUMBER,
    client_session_id     VARCHAR(256),
    client_ip             VARCHAR(45),
    client_application_id VARCHAR(256),
    client_environment    VARIANT,
    action_type           VARCHAR(100) NOT NULL,
    action_category       VARCHAR(50),
    object_type           VARCHAR(100),
    object_name           VARCHAR(512),
    object_database       VARCHAR(256),
    object_schema         VARCHAR(256),
    query_id              VARCHAR(256),
    query_text            TEXT,
    query_tag             VARCHAR(2000),
    execution_status      VARCHAR(50),
    error_code            NUMBER,
    error_message         TEXT,
    rows_affected         NUMBER,
    bytes_scanned         NUMBER,
    execution_time_ms     NUMBER,
    streamlit_app_name    VARCHAR(256),
    streamlit_page        VARCHAR(256),
    streamlit_component   VARCHAR(256),
    streamlit_action      VARCHAR(256),
    request_payload       VARIANT,
    response_payload      VARIANT,
    correlation_id        VARCHAR(256),
    parent_correlation_id VARCHAR(256),
    tags                  VARIANT,
    metadata              VARIANT,
    created_at            TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP(),
    source_system         VARCHAR(100) DEFAULT 'STREAMLIT_APP'
);

-- search optimization (run once, skip if 'already exists' error returned)
ALTER TABLE {database}.{schema}.AUDIT_LOG
    ADD SEARCH OPTIMIZATION ON EQUALITY(
        user_name, role_name, action_type, action_category,
        object_name, query_id, correlation_id, streamlit_app_name, execution_status
    );

ALTER TABLE {database}.{schema}.AUDIT_LOG
    ADD SEARCH OPTIMIZATION ON SUBSTRING(query_text, error_message, object_name);

ALTER TABLE {database}.{schema}.AUDIT_LOG
    CLUSTER BY (event_timestamp, action_type);

-- V_APP_EVENTS view
CREATE OR REPLACE VIEW {database}.{schema}.V_APP_EVENTS AS
SELECT
    TIMESTAMP,
    RESOURCE_ATTRIBUTES,
    RECORD_TYPE,
    RECORD,
    RECORD_ATTRIBUTES,
    SCOPE,
    VALUE
FROM {database}.{schema}.APP_EVENTS
WHERE SCOPE['name']::STRING LIKE '%{schema}%'
   OR RESOURCE_ATTRIBUTES['snow.database.name']::STRING = '{database}';

-- LOG_AUDIT_EVENT procedure
--
-- SiS user context warning: in Streamlit in Snowflake, CURRENT_USER() returns the app
-- service account (app owner), NOT the logged-in user. SiS callers MUST pass the logged-in
-- user as p_user_name using st.user.user_name. SQL CALL sites (agent operations) may
-- omit p_user_name, CURRENT_USER() is correct there (agent runs as the actual user).
CREATE OR REPLACE PROCEDURE {database}.{schema}.LOG_AUDIT_EVENT(
    p_action_type         VARCHAR,
    p_action_category     VARCHAR,
    p_streamlit_app_name  VARCHAR,
    p_streamlit_page      VARCHAR,
    p_streamlit_component VARCHAR,
    p_streamlit_action    VARCHAR,
    p_request_payload     VARIANT,
    p_response_payload    VARIANT,
    p_correlation_id      VARCHAR,
    p_tags                VARIANT,
    p_metadata            VARIANT,
    p_user_name           VARCHAR DEFAULT NULL
)
RETURNS VARCHAR
LANGUAGE SQL
AS
$$
BEGIN
    INSERT INTO {database}.{schema}.AUDIT_LOG (
        user_name, role_name, session_id, action_type, action_category, query_id,
        streamlit_app_name, streamlit_page, streamlit_component, streamlit_action,
        request_payload, response_payload, correlation_id, tags, metadata, execution_status
    )
    SELECT
        COALESCE(:p_user_name, CURRENT_USER()), CURRENT_ROLE(), CURRENT_SESSION(),
        :p_action_type, :p_action_category, LAST_QUERY_ID(),
        :p_streamlit_app_name, :p_streamlit_page, :p_streamlit_component, :p_streamlit_action,
        :p_request_payload, :p_response_payload, :p_correlation_id, :p_tags, :p_metadata,
        'SUCCESS';
    RETURN 'Audit event logged successfully';
END;
$$;
