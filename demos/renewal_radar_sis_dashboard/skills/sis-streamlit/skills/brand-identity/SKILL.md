---
name: brand-identity
description: "load the visual identity, chart type rules, style defaults, and language conventions for the renewal radar dashboard. trigger before generating any Streamlit code - after build-dashboard (no args). do NOT use for SiS API constraints (those are in build-dashboard) or for Snowflake environment checks."
---

-> Load `references/altair-docs.md` on every invocation - Altair mark types, encoding shorthands, axis formatting, legend placement, complete chart examples.

## colors

load these values into context and use them consistently across all pages.

### primary palette

| token | hex | usage |
|---|---|---|
| primary | #1565C0 | trend lines, primary bars, "RENEWED" state, heatmap high end |
| accent | #FFA726 | "non-renewed" states (LAPSED, NOT_TAKEN_UP, CANCELLED), warnings |

### status palette (for tabular data)

| status | background | text | usage |
|---|---|---|---|
| SUCCESS / OK | #d4edda | inherit | AUDIT_LOG execution_status |
| WARN | #fff3cd | inherit | AUDIT_LOG execution_status |
| ERROR | #f8d7da | inherit | AUDIT_LOG execution_status |

### heatmap gradient (renewal_rate: low -> high)

| threshold | background | text |
|---|---|---|
| >= 80% | #0D47A1 | #ffffff |
| >= 70% | #1565C0 | #ffffff |
| >= 60% | #1976D2 | #ffffff |
| >= 50% | #42A5F5 | #222222 |
| < 50% | #BBDEFB | #222222 |

---

## chart type rules

use these rules to select the correct chart type for each use case.
**do NOT use `st.bar_chart` or `st.line_chart`** - use Altair for all charts.
reasons: native Streamlit charts cannot format axis values as percentages and do not support horizontal layout.

| use case | chart type | Altair method |
|---|---|---|
| metric trend over time | line with points | `mark_line(color=..., point=True)` |
| single metric by category - SHORT labels (<=8 categories, codes or bands) | vertical bar (column) | `mark_bar(color=...)` + `alt.X("cat:N", sort="-y")` + `alt.Y("metric:Q")` |
| single metric by category - LONG labels (many categories or full text names) | horizontal bar | `mark_bar(color=...)` + `alt.Y("cat:N", sort="-x")` + `alt.X("metric:Q")` |
| outcome distribution by category (stacked) | horizontal stacked bar | `alt.Y(category)` + `alt.X(metric)` + `alt.Color(outcome)` |
| two-dimension breakdown (rows x cols -> value) | heatmap via pandas pivot + `st.dataframe(styled)` | `df.style.format(...).map(color_fn)` |

**vertical vs horizontal bar decision rule:**
- use vertical (column) when: category labels are SHORT (region codes: TX, MO; bands: 0_TO_5, 5_TO_10; outcomes: RENEWED), count <= 8
- use horizontal when: category labels are LONG (segment names, full text), count > 8, or when stacking outcomes
- `renewal rate by region` -> vertical (region codes are 2-letter)
- `avg premium change by renewal_outcome` -> vertical (outcome names are short, <= 4 values)
- `avg premium change by price_shock_band` -> vertical (band codes are short)
- `outcome distribution by segment` -> horizontal stacked (segment names are long)

---

## chart style defaults

apply these defaults to every Altair chart unless a specific exception is noted.

### axes

- **percentage Y axis**: `alt.Y("...:Q", axis=alt.Axis(format=":.1%"))` for rates (renewal_rate, leakage_rate, etc.)
- **percentage Y axis (bands)**: `alt.Y("...:Q", axis=alt.Axis(format=":.0%"))` for premium_change_pct (whole percent sufficient)
- **categorical X axis with text labels**: always add `axis=alt.Axis(labelAngle=0)` - prevents diagonal labels
- **time X axis**: always add `title=None` to suppress the axis title; use adaptive granularity: day (<=30 days), week (31-180 days), month (>180 days)
- **axis titles - always explicit**: always set `title=` on both `alt.X()` and `alt.Y()`.
  never rely on Altair defaults - they render raw field names (e.g. "renewal_outcome", "avg_change", "renewal_rate").
  titles must be sentence case with spaces: "Renewal rate", "Renewal outcome", "Average premium change".
  exception: time-series X axis uses `title=None` to suppress the axis title (see above).
- **time X axis - aggregation is mandatory**: aggregate dates in SQL using `DATE_TRUNC` before charting. do NOT plot raw `renewal_date` values and rely on Altair formatting to group them - that produces one point per policy (jagged, broken line). query pattern:
  ```sql
  SELECT DATE_TRUNC('month', renewal_date) AS period,
         SUM(is_renewed) * 1.0 / COUNT(*) AS renewal_rate
  FROM FACT_RENEWAL
  GROUP BY period ORDER BY period
  ```
  use `'day'`, `'week'`, or `'month'` in `DATE_TRUNC` based on the date range of filtered data. Altair encoding: `alt.X("period:T", title=None)`

### legends

- **single-color charts** (fixed color on `mark_*`): do NOT add `alt.Color` encoding - no legend appears, which is correct
- **multi-color charts** (color encodes a dimension): use `alt.Color("FIELD:N", legend=alt.Legend(orient="top", title="..."))` - legend always on top
- **do NOT put `legend=` on `alt.X()` or `alt.Y()`** - it is not a valid parameter and causes `SchemaValidationError`

### stacked horizontal bar - label truncation

for segment labels (can be long): always set `axis=alt.Axis(labelLimit=200)` on the Y encoding.

---

## language conventions

### KPI card labels

- sentence case, no abbreviations
- correct: "Renewal rate", "Leakage rate", "Quote-to-bind rate", "Service delay index"
- incorrect: "Rnwl Rate", "LKG RATE", "QTB", "SvcDelayIdx"

### percentage display

- always 1 decimal place: "72.4%", "8.1%"
- exception: premium change band labels (whole percent is sufficient): "10%", "20%"

### filter labels

- date filter labels: "Renewal date from" and "Renewal date to" (two separate `st.date_input` widgets)
- always use `format="YYYY-MM-DD"` on all `st.date_input` calls - prevents locale-default YYYY/MM/DD display
- default date range: last 30 days (`max_date - timedelta(days=30)` to `max_date`)

### interactive controls

- button labels: imperative verb + object - "Submit flag", "Mark reviewed"
- text input placeholder: lowercase - "enter reason for flagging..."
- selectbox empty first option: empty string `""` (not "Select...", not "All")
- toggle label: descriptive noun phrase - "Final Offers Only"

### section headings

- title case for page titles: "Premium Pressure Analysis"
- sentence case for section headings within a page: "Flag for review"
- no trailing punctuation on headings

---

## display labels

all raw database values MUST be transformed to human-readable text before display.
this applies to every chart, filter widget, and table in the dashboard.
SQL queries, session_state values, and audit log payloads always use raw values - only the presentation layer changes.

### label mapping dictionaries

define these constants in `dashboard.py` after the DATABASE/SCHEMA/APP_NAME block and before the cached data loader:

```python
REGION_LABELS  = {
    "AR": "Arkansas", "TX": "Texas", "LA": "Louisiana", "MO": "Missouri",
    "OK": "Oklahoma", "TN": "Tennessee", "KS": "Kansas",
}
SEGMENT_LABELS = {
    "PERSONAL_AUTO": "Personal auto", "COMMERCIAL_PROPERTY": "Commercial property",
    "COMMERCIAL_VAN": "Commercial van", "HOME": "Home",
    "PERSONAL_MOTORBIKE": "Personal motorbike",
}
CHANNEL_LABELS = {"AGENT": "Agent", "BROKER": "Broker", "DIRECT": "Direct"}
OUTCOME_LABELS = {
    "RENEWED": "Renewed", "LAPSED": "Lapsed",
    "NOT_TAKEN_UP": "Not taken up", "CANCELLED": "Cancelled",
}
BAND_LABELS    = {
    "0_TO_5": "0-5%", "5_TO_10": "5-10%",
    "10_TO_15": "10-15%", "GT_15": ">15%",
}
STATUS_LABELS  = {"OPEN": "Open", "REVIEWED": "Reviewed"}

# reverse mappings (display -> raw) - used to convert selectbox/multiselect results back to raw values before SQL
REGION_LABELS_REV  = {v: k for k, v in REGION_LABELS.items()}
SEGMENT_LABELS_REV = {v: k for k, v in SEGMENT_LABELS.items()}
CHANNEL_LABELS_REV = {v: k for k, v in CHANNEL_LABELS.items()}

# display sort orders (logical, not alphabetical) - use for Altair domain/sort params
OUTCOME_DISPLAY_ORDER = ["Renewed", "Lapsed", "Not taken up", "Cancelled"]
BAND_DISPLAY_ORDER    = ["0-5%", "5-10%", "10-15%", ">15%"]
```

### usage rules

**sidebar filter widgets (multiselect):** add `format_func` to show display labels while storing raw values in session_state:
```python
sel_regions = st.sidebar.multiselect(
    "Region", VALID_REGIONS, key="sel_regions",
    format_func=lambda x: REGION_LABELS.get(x, x)
)
```
session_state still stores raw values (["TX", "LA"]) - do NOT convert them to display labels.

**charts:** add a display column to the DataFrame before Altair encoding:
```python
df["region_display"]  = df["region"].map(REGION_LABELS)
df["outcome_display"] = df["renewal_outcome"].map(OUTCOME_LABELS)
df["band_display"]    = df["price_shock_band"].map(BAND_LABELS)
# use the display column in Altair encoding, not the raw column
alt.X("region_display:N", ...)
alt.Color("outcome_display:N", domain=OUTCOME_DISPLAY_ORDER, ...)
```

**flag form selectboxes (page 2):** display labels, but convert back to raw before SQL:
```python
flag_region_display = st.selectbox("Region", [""] + [REGION_LABELS[r] for r in VALID_REGIONS])
flag_region = REGION_LABELS_REV.get(flag_region_display)  # raw value for SQL
```

**tables (page 3):** map display columns after query, before rendering:
```python
df["status"] = df["STATUS"].map(STATUS_LABELS)
df["scope_region"] = df["SCOPE_REGION"].map(REGION_LABELS)
```

**data integrity rules - NO EXCEPTIONS:**
- SQL WHERE clauses always use raw values: `WHERE region IN ('TX', 'LA')` - never "Texas"
- session_state stores raw values: `st.session_state["sel_regions"] = ["TX"]` - never "Texas"
- audit log payloads use raw constants: `log_audit_event("FILTER_CHANGE", ...)` - never "Filter change"
- whitelist validation uses raw VALID_REGIONS list: `[r for r in user_selected if r in VALID_REGIONS]`

---

## heatmap implementation

the renewal_rate heatmap on page 2 uses `st.dataframe` with pandas styling.
use `.map()`, NOT `.applymap()` (`.applymap()` was removed in pandas 2.2).

```python
def color_heatmap(val):
    if val is None or pd.isna(val):
        return ""
    v = float(val)
    if v >= 0.80:
        return "background-color: #0D47A1; color: #ffffff"
    elif v >= 0.70:
        return "background-color: #1565C0; color: #ffffff"
    elif v >= 0.60:
        return "background-color: #1976D2; color: #ffffff"
    elif v >= 0.50:
        return "background-color: #42A5F5; color: #222222"
    else:
        return "background-color: #BBDEFB; color: #222222"

styled = pivot_df.style.format("{:.1%}").map(color_heatmap)
st.dataframe(styled, use_container_width=True)
```

---

## status color coding

for AUDIT_LOG tables (tab 2 - agent operations). use `.map()`, NOT `.applymap()`.

```python
def color_status(val):
    colors = {
        "SUCCESS": "background-color: #d4edda",
        "OK": "background-color: #d4edda",
        "WARN": "background-color: #fff3cd",
        "ERROR": "background-color: #f8d7da",
    }
    return colors.get(val, "")

styled = df.style.map(color_status, subset=["EXECUTION_STATUS"])
st.dataframe(styled, use_container_width=True)
```

## success criteria

- all charts use Altair (no `st.bar_chart`, `st.line_chart`)
- primary color (#1565C0) used for all single-color positive-state charts
- accent color (#FFA726) used for non-renewed / negative states
- all percentage axes formatted to 1 decimal place (except premium bands: 0 decimals)
- all categorical X axes with text labels have `labelAngle=0`
- all multi-color legends are `orient="top"`
- KPI labels are sentence case with no abbreviations
- `.map()` used (not `.applymap()`) for all pandas styling
- all `alt.X()` and `alt.Y()` encodings have explicit `title=` (except time-series X which uses `title=None`)
- REGION_LABELS, SEGMENT_LABELS, CHANNEL_LABELS, OUTCOME_LABELS, BAND_LABELS, STATUS_LABELS defined in dashboard.py
- all multiselect widgets have `format_func` referencing the appropriate label dict
- all chart DataFrames have display columns mapped before Altair encoding (e.g. `region_display`, `outcome_display`)
- SQL queries, session_state values, and audit log payloads use raw values only (never display labels)
