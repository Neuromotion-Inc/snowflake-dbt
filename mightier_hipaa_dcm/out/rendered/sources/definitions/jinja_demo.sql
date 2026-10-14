-- loop through lists

    

    -- inject dictionary values directly into object properties
    define schema DCM_DEMO_1_DEV.SAMPLE_TEAM
        comment = 'using JINJA dictionary values'
        data_retention_time_in_days = 1;

    -- Run the macro to create all roles and grants for this schema
    
    
    define role SAMPLE_TEAM_DEVELOPER_DEV;
    define role SAMPLE_TEAM_USAGE_DEV;

    grant USAGE     on database DCM_DEMO_1_DEV        to role SAMPLE_TEAM_USAGE_DEV;
    grant USAGE     on schema DCM_DEMO_1_DEV.SAMPLE_TEAM to role SAMPLE_TEAM_USAGE_DEV;

    grant CREATE DYNAMIC TABLE, CREATE TABLE, CREATE VIEW on schema DCM_DEMO_1_DEV.SAMPLE_TEAM to role SAMPLE_TEAM_DEVELOPER_DEV;
    
    grant role SAMPLE_TEAM_USAGE_DEV     to role SAMPLE_TEAM_DEVELOPER_DEV;
    grant role SAMPLE_TEAM_DEVELOPER_DEV     to role DCM_DEVELOPER;
    -- ensure the project owner role retains all granted roles to avoid lock-out
    

        
    define table DCM_DEMO_1_DEV.SAMPLE_TEAM.PRODUCTS(
        ITEM_NAME varchar,
        ITEM_ID varchar,
        ITEM_CATEGORY array
    );
      
    -- define conditions 
    
        define table DCM_DEMO_1_DEV.SAMPLE_TEAM.EMPLOYEES(
            NAME varchar,
            ID int
        )
        comment = 'This table is only created in HR'
        ;
    



-- ### check the jinja_demo file in the PLAN output to see the rendered jinja 