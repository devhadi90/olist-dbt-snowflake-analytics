-- =============================================================================
-- macros/generate_schema_name.sql
--
-- Controls how dbt resolves schema names across targets.
--
-- Behaviour:
--   dev target   → <dev_prefix>_<model_schema>
--                  e.g. hadi_staging, hadi_marts
--   ci target    → ci  (all models land in the ci schema, isolated)
--   staging/prod → <model_schema> as declared in dbt_project.yml
--                  e.g. staging, intermediate, marts
--
-- This prevents dev runs from overwriting prod schemas.
-- =============================================================================

{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}

    {%- if target.name == 'ci' -%}
        {# All CI models go into the single ci schema for easy cleanup #}
        ci

    {%- elif target.name == 'dev' -%}
        {# Dev: prefix every schema with the target schema value (your name) #}
        {%- if custom_schema_name is none -%}
            {{ default_schema }}
        {%- else -%}
            {{ default_schema }}_{{ custom_schema_name | trim }}
        {%- endif -%}

    {%- else -%}
        {# staging / prod: use the schema name exactly as declared #}
        {%- if custom_schema_name is none -%}
            {{ default_schema }}
        {%- else -%}
            {{ custom_schema_name | trim }}
        {%- endif -%}

    {%- endif -%}

{%- endmacro %}
