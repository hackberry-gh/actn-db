CREATE SCHEMA core;
SET search_path TO core,public;

SELECT plv8_startup();

SELECT __create_table('core','models');
SELECT __create_index('core','models', '{"cols": {"name": "text"},"unique": true}');


CREATE or REPLACE FUNCTION model_callbacks() RETURNS trigger AS $$
  actn.funcs.model_callbacks(TG_OP, NEW, OLD);
$$ LANGUAGE plv8 STABLE STRICT;

CREATE TRIGGER core_models_callback_trigger 
AFTER INSERT OR UPDATE OR DELETE ON core.models
FOR EACH ROW EXECUTE PROCEDURE model_callbacks();