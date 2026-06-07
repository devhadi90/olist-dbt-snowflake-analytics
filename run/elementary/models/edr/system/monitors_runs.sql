
  create or replace   view olist_analytics.staging_deploy.monitors_runs
  
  
  
  
  as (
    

with
    data_monitoring_metrics as (select * from olist_analytics.staging_deploy.data_monitoring_metrics),

    max_bucket_end as (

        select
            full_table_name,
            column_name,
            metric_name,
            metric_properties,
            max(bucket_end) as last_bucket_end,
            min(bucket_end) as first_bucket_end
        from data_monitoring_metrics
        group by full_table_name, column_name, metric_name, metric_properties

    )

select *
from max_bucket_end
  );

