{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set prefix = env_var('DBT_ENV_SCHEMA_PREFIX', '') | trim -%}

    {%- if custom_schema_name is none -%}
        {%- if prefix != '' -%}
            {{ prefix | lower }}
        {%- else -%}
            {{ target.schema }}
        {%- endif -%}

    {%- else -%}
        {%- if prefix != '' -%}
            {{ prefix | lower }}_{{ custom_schema_name | trim }}
        {%- else -%}
            {{ custom_schema_name | trim }}
        {%- endif -%}

    {%- endif -%}

{%- endmacro %}
