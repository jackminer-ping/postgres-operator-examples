--- Need to create db

--CREATE database hippo;

--- Change to hippo db
\c hippo;

--- Create schema
--CREATE SCHEMA hippo;
-- uses postgres schema...

--- Create role/user for each region
--CREATE ROLE hippo_role WITH LOGIN PASSWORD 'hippotest';
CREATE ROLE pf_replication_secondary WITH LOGIN PASSWORD 'hippotest';
CREATE ROLE pf_replication_primary WITH LOGIN PASSWORD 'hippotest';


--GRANT ALL PRIVILEGES ON SCHEMA hippo TO hippo_role;

GRANT ALL PRIVILEGES ON SCHEMA hippo TO pf_replication_secondary;
GRANT ALL PRIVILEGES ON SCHEMA hippo TO pf_replication_primary;


--- First portion
CREATE EXTENSION IF NOT EXISTS pgnodemx;


-- Change to (postgres-operator.crunchydata.com/cluster) ????
-- CREATE OR REPLACE FUNCTION hippo.get_node_name()
-- RETURNS text
-- AS $$
--   SELECT val FROM kdapi_setof_kv('labels') WHERE key='pg-cluster';
-- $$ LANGUAGE SQL SECURITY DEFINER IMMUTABLE;

CREATE OR REPLACE FUNCTION hippo.get_node_name()
RETURNS text
AS $$
  SELECT val FROM kdapi_setof_kv('labels') WHERE key='postgres-operator.crunchydata.com/cluster';
$$ LANGUAGE SQL SECURITY DEFINER IMMUTABLE;

--- hippo user doesn't actually exist
GRANT EXECUTE ON FUNCTION hippo.get_node_name() TO hippo_role;


--- Second portion
CREATE TABLE hippo.hippos (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    node_name text,
    value numeric,
    created_at timestamptz
) PARTITION BY LIST (node_name);

CREATE TABLE hippo.hippo_default PARTITION of hippo.hippos (PRIMARY KEY (id)) DEFAULT;
CREATE TABLE hippo.hippo_one PARTITION OF hippo.hippos (PRIMARY KEY (id)) FOR VALUES IN ('hippo-one');
CREATE TABLE hippo.hippo_two PARTITION OF hippo.hippos (PRIMARY KEY (id)) FOR VALUES IN ('hippo-two');

CREATE OR REPLACE FUNCTION add_node_name()
RETURNS trigger AS $$
BEGIN
  UPDATE hippo.hippos
    SET node_name = hippo.get_node_name()
    WHERE node_name IS NULL;

  RETURN NULL;
END
$$ LANGUAGE plpgsql;

CREATE TRIGGER add_node_name
AFTER INSERT ON hippo.hippos
  FOR EACH STATEMENT
  EXECUTE FUNCTION add_node_name();



--- Replication (under postgres db?)

ALTER ROLE hippo_role REPLICATION;


-- on one
CREATE PUBLICATION pub_hippo_one FOR TABLE hippo.hippo_one;

-- on two
CREATE PUBLICATION pub_hippo_two FOR TABLE hippo.hippo_two;


-- SUB one->two

CREATE SUBSCRIPTION sub_hippo_one_hippo_two
  CONNECTION 'dbname=hippo host=ae446b62cb3a249c88c71c3f181dee1f-1766679677.us-west-2.elb.amazonaws.com user=hippo_role password=hippotest'
  PUBLICATION pub_hippo_two;

-- SUB two-> one
CREATE SUBSCRIPTION sub_hippo_two_hippo_one_v2
  CONNECTION 'dbname=hippo host=a167954e340a24bd8b54bdb1febb9a31-1389954011.us-west-2.elb.amazonaws.com user=hippo_role password=hippotest'
  PUBLICATION pub_hippo_one;


-- view replication status?
select * from pg_stat_replication;

--- Needed to start replication, per https://access.crunchydata.com/documentation/postgres-operator/v5/guides/logical-replication/

hippo=# GRANT SELECT ON hippo.hippos to hippo_role;
GRANT
hippo=# GRANT SELECT ON hippo.hippo_one to hippo_role;
GRANT
hippo=# GRANT SELECT ON hippo.hippo_two to hippo_role;
GRANT
