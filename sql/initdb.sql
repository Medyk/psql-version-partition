-- Table: public.version_test

 

-- DROP TABLE public.version_test;

 

CREATE TABLE IF NOT EXISTS public.version_test

(

    id bigint NOT NULL DEFAULT nextval('version_test_id_seq'::regclass),

    version_from date NOT NULL,

    version_to date NOT NULL,

    value character varying(50) COLLATE pg_catalog."default",

    CONSTRAINT version_test_pkey PRIMARY KEY (id, version_from)

) PARTITION BY RANGE (version_from);

 

ALTER TABLE public.version_test

    OWNER to postgres;

-- Index: id_idx

 

-- DROP INDEX public.id_idx;

 

CREATE INDEX id_idx

    ON public.version_test USING btree

    (id ASC NULLS LAST)

;

 

-- Partitions SQL

 

CREATE TABLE IF NOT EXISTS public.version_test_current PARTITION OF public.version_test

    DEFAULT;

 

ALTER TABLE public.version_test_current

    OWNER to postgres;

CREATE TABLE IF NOT EXISTS public.version_test_history_2021_q1 PARTITION OF public.version_test

(

    CONSTRAINT version_test_history_2021_q1_version_to_check CHECK (version_to <= '2021-05-20'::date)

)

    FOR VALUES FROM ('2021-01-01') TO ('2021-04-01');

 

ALTER TABLE public.version_test_history_2021_q1

    OWNER to postgres;

CREATE TABLE IF NOT EXISTS public.version_test_history_2021_q2 PARTITION OF public.version_test

(

    CONSTRAINT version_test_history_2021_q2_version_to_check CHECK (version_to <= '1800-01-01'::date)

)

    FOR VALUES FROM ('2021-04-01') TO ('2021-07-01');

 

ALTER TABLE public.version_test_history_2021_q2

    OWNER to postgres;

CREATE TABLE IF NOT EXISTS public.version_test_history_2021_q3 PARTITION OF public.version_test

(

    CONSTRAINT version_test_history_2021_q3_version_to_check CHECK (version_to <= '2021-08-20'::date)

)

    FOR VALUES FROM ('2021-07-01') TO ('2021-10-01');

 

ALTER TABLE public.version_test_history_2021_q3

    OWNER to postgres;

CREATE TABLE IF NOT EXISTS public.version_test_history_pre_2021 PARTITION OF public.version_test

(

    CONSTRAINT version_test_history_pre_2021_version_to_check CHECK (version_to <= '1800-01-01'::date)

)

    FOR VALUES FROM ('1800-01-01') TO ('2021-01-01');

 

ALTER TABLE public.version_test_history_pre_2021

    OWNER to postgres;

 

 

-- https://dba.stackexchange.com/questions/2804/how-can-i-use-a-default-value-in-a-select-query-in-postgresql

 

SET enable_partition_pruning = on;

 

DROP TABLE version_test;

CREATE TABLE version_test (

                id bigserial NOT NULL,

                version_from date NOT NULL,

    version_to date NOT NULL,

                value character varying(50) COLLATE pg_catalog."default",

    CONSTRAINT version_test_pkey PRIMARY KEY (id, version_from)

) PARTITION BY RANGE (version_from);

 

CREATE INDEX id_idx ON version_test (id);

 

CREATE TABLE version_test_current PARTITION OF version_test DEFAULT;

CREATE TABLE version_test_history_pre_2021 PARTITION OF version_test FOR VALUES FROM ('1800-01-01') TO ('2021-01-01');

CREATE TABLE version_test_history_2021_q1 PARTITION OF version_test FOR VALUES FROM ('2021-01-01') TO ('2021-04-01');

CREATE TABLE version_test_history_2021_q2 PARTITION OF version_test FOR VALUES FROM ('2021-04-01') TO ('2021-07-01');

CREATE TABLE version_test_history_2021_q3 PARTITION OF version_test FOR VALUES FROM ('2021-07-01') TO ('2021-10-01');

CREATE TABLE version_test_history_2021_q4 PARTITION OF version_test FOR VALUES FROM ('2021-10-01') TO ('2022-01-01');

 

--  SELECT '1800-01-01' as version_min, case count(1) when 0 then '1800-01-01' else max(version_to) end as version_max FROM version_test_history_pre_2021;

--  ALTER TABLE version_test_history_pre_2021 ADD CHECK (version_to <= '1800-01-01');

 

--  SELECT '2021-01-01' as version_min, case count(1) when 0 then '2021-01-01' else max(version_to) end as version_max FROM version_test_history_2021_q1;

--  ALTER TABLE version_test_history_2021_q1 ADD CHECK (version_to <= '2021-05-20');

 

--  SELECT '2021-04-01' as version_min, case count(1) when 0 then '2021-04-01' else max(version_to) end as version_max FROM version_test_history_2021_q2;

--  ALTER TABLE version_test_history_2021_q2 ADD CHECK (version_to <= '1800-01-01');

 

--  SELECT '2021-07-01' as version_min, case count(1) when 0 then '2021-07-01' else max(version_to) end as version_max FROM version_test_history_2021_q3;

--  ALTER TABLE version_test_history_2021_q2 ADD CHECK (version_to <= '2021-08-20');

 

 

-- create new partition

-- ALTER TABLE version_test DETACH PARTITION version_test_current;

-- CREATE TABLE version_test_history_2021_q4 PARTITION OF version_test FOR VALUES FROM ('2021-10-01') TO ('2022-01-01');

-- WITH q_data (DELETE FROM version_test_current WHERE version_from >= '2021-10-01' AND version_from < '2022-01-01' RETURNING *)

--     INSERT INTO version_test_history_2021_q4 SELECT * FROM q_data;

-- ALTER TABLE version_test ATTACH PARTITION version_test_history_2021_q4 FOR VALUES FROM ('2021-10-01') TO ('2022-01-01');

-- ALTER TABLE version_test ATTACH PARTITION version_test_current DEFAULT;

 

 

INSERT INTO version_test (version_from, version_to, value) VALUES ('2021-01-10', '2021-05-20', '1');

 

INSERT INTO version_test (version_from, version_to, value) VALUES ('2021-07-10', '2021-07-20', '1');

INSERT INTO version_test (version_from, version_to, value) VALUES ('2021-07-20', '2021-08-10', '2');

INSERT INTO version_test (version_from, version_to, value) VALUES ('2021-08-10', '2021-08-20', '3');

INSERT INTO version_test (version_from, version_to, value) VALUES ('2021-10-20', '9999-12-31', '4');

 

 

EXPLAIN SELECT * FROM version_test WHERE

'2021-07-20' BETWEEN version_from AND version_to;

 

EXPLAIN SELECT * FROM version_test WHERE daterange(version_from, version_to) && daterange('[2021-07-20, 2021-07-20]') AND version_to < '2021-07-20';

 

EXPLAIN SELECT * FROM version_test WHERE tstzrange(version_from, version_to) @> current_timestamp;

 

 

EXPLAIN SELECT * FROM version_test WHERE '2021-10-01' BETWEEN version_from AND version_to;

EXPLAIN SELECT * FROM version_test WHERE version_to BETWEEN '2021-10-01' AND '2021-10-31';

EXPLAIN SELECT * FROM version_test WHERE version_to >= DATE '2100-01-01';

 

 

SELECT tableoid::regclass, * FROM version_test;

SELECT tableoid::regclass, * FROM version_test_current;

SELECT tableoid::regclass, * FROM version_test_history;