define warehouse DCM_DEMO_1_WH_DEV
with
    warehouse_size = 'XSMALL'
    auto_suspend = 300
    comment = 'For Quickstart Demo of DCM Projects'
;

define database DCM_DEMO_1_DEV
    comment = 'This is a Quickstart Demo for DCM Projects Private Preview';

define schema DCM_DEMO_1_DEV.ANALYTICS
    comment = 'For Task copying sample data into landing tables';

define table DCM_DEMO_1_DEV.ANALYTICS.ALL_ITEMS(
    ITEM_NAME varchar,
    ITEM_ID varchar,
    ITEM_CATEGORY array
)
change_tracking = TRUE;

define dynamic table DCM_DEMO_1_DEV.ANALYTICS.DRINKS
    warehouse = DCM_DEMO_1_WH_DEV
    target_lag = '6 hours'
    initialize = 'ON_CREATE'
  as
    select
        *
    from
        DCM_DEMO_1_DEV.ANALYTICS.ALL_ITEMS
    where
        ARRAY_CONTAINS('DRINKS'::variant, ITEM_CATEGORY)
;

define role DCM_DEMO_1_DEV_READ;

grant USAGE on database DCM_DEMO_1_DEV to role DCM_DEMO_1_DEV_READ;
grant USAGE on schema DCM_DEMO_1_DEV.ANALYTICS to role DCM_DEMO_1_DEV_READ;
grant SELECT on ALL tables in database DCM_DEMO_1_DEV to role DCM_DEMO_1_DEV_READ;
grant SELECT on dynamic table DCM_DEMO_1_DEV.ANALYTICS.DRINKS to role DCM_DEMO_1_DEV_READ;