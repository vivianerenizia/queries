DROP TABLE IF EXISTS db.table_name CASCADE;

CREATE TABLE db.table_name(
    id serial primary key,
    object_type varchar(20),
    schema_name varchar(50),
    object_identity varchar(200),
    creation_date timestamp without time zone 
    );

-- -- -- --  --  --  --  --  --  --  --  --
-- TRIGGER E FUNÇÃO INSERIR NA METATABLE --
-- -- -- --  --  --  --  --  --  --  --  --

-- dropa o trigger de inserir na metatable antes de dropar a função
DROP EVENT TRIGGER IF EXISTS t_create_tables_inventory_trigger;

-- dropa a função de inserir na metatable
DROP FUNCTION IF EXISTS db.t_create_tables_inventory_func();

-- função que insere os dados de uma nova tabela na metatable
CREATE OR REPLACE FUNCTION db.t_create_tables_inventory_func()
RETURNS event_trigger
LANGUAGE plpgsql
AS $$
DECLARE
    obj record;
begin
	FOR obj IN SELECT * FROM pg_event_trigger_ddl_commands () WHERE command_tag in ('SELECT INTO','CREATE TABLE','CREATE TABLE AS')
    LOOP
        INSERT INTO db.ttables_inventory (object_type, schema_name, object_identity, creation_date) SELECT obj.object_type, obj.schema_name, obj.object_identity, now();
    END LOOP;
END;
$$;

-- trigger que dispara a função de inserir os dados de uma nova tabela na metatable
CREATE EVENT TRIGGER t_create_tables_inventory_trigger ON ddl_command_end
WHEN TAG IN ('SELECT INTO','CREATE TABLE','CREATE TABLE AS')
EXECUTE PROCEDURE db.t_create_tables_inventory_func();

-- -- -- --  --  --  --  --  --  --  --  --
-- TRIGGER E FUNÇÃO DELETAR DA METATABLE --
-- -- -- --  --  --  --  --  --  --  --  --

-- dropa o trigger de deletar as linhas da metatable antes de dropar a função
DROP EVENT TRIGGER IF EXISTS t_delete_rows_inventory_trigger;

-- dropa a função de deletar da metatable
DROP FUNCTION IF EXISTS db.t_delete_rows_inventory_func();

--  função que deleta os dados da metatable se uma tabela for excluída
CREATE OR REPLACE FUNCTION db.t_delete_rows_inventory_func()
RETURNS event_trigger
LANGUAGE plpgsql
AS $$
DECLARE
    obj record;
begin
	FOR obj IN SELECT * FROM pg_event_trigger_dropped_objects()
    LOOP
    	delete from db.ttables_inventory where object_identity = obj.object_identity;
    END LOOP; 
END;
$$;

-- trigger que dispara a função de deletar os dados da metatable se uma tabela for excluída
CREATE EVENT TRIGGER t_delete_rows_inventory_trigger ON sql_drop 
WHEN TAG IN ('DROP TABLE')
EXECUTE PROCEDURE db.t_delete_rows_inventory_func();
