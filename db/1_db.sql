CREATE SCHEMA core;
SET search_path TO core,public;

SELECT plv8_startup();

SELECT __create_table('core','models');
SELECT __create_index('core','models', '{"cols": {"name": "text"},"unique": true}');


CREATE or REPLACE FUNCTION model_callbacks() RETURNS trigger AS
$$
  table_name = (NEW?.data?.name or OLD?.data?.name)?.tableize()
  table_schema = (NEW?.data?.table_schema or OLD?.data?.table_schema) or "public"

  return if table_schema is "core"
  
  # plv8.elog(NOTICE,"MODEL CALLBACKS",table_schema,JSON.stringify(NEW?.data or OLD?.data))
  
  mapper = (ind) -> _.keys(ind.cols)
  differ = (_ind) ->
    (ind) ->  
      _.isEmpty( _.difference( _.keys(ind.cols), _.flatten( _.map( _ind.data?.indexes, mapper ) ) ) )
  
  switch TG_OP
    when "INSERT"
      plv8.execute "SELECT __create_table($1,$2)",[table_schema , table_name]
      
      plv8.execute "SELECT __create_index($1,$2,$3)", [table_schema, table_name, {cols: {path: "text" }}]
      
      for indopts in NEW?.data?.indexes or []
        plv8.execute "SELECT __create_index($1,$2,$3)", [table_schema, table_name, indopts]
        
    when "UPDATE"
        
      diff  = _.reject( OLD?.data?.indexes, differ(NEW) )
      
      for indopts in diff
        plv8.execute "SELECT __drop_index($1,$2,$3)", [table_schema, table_name, indopts]
        
      diff  = _.reject( NEW?.data?.indexes, differ(OLD) )
      
      for indopts in diff
        plv8.execute "SELECT __create_index($1,$2,$3)", [table_schema, table_name, indopts]
        
    when "DELETE"
      for indopts in Old?.data?.indexes or []
        plv8.execute "SELECT __drop_index($1,$2,$3)", [table_schema, table_name, indopts]
      plv8.execute "SELECT __drop_table($1,$2)",[table_schema , table_name]
    
$$ LANGUAGE plcoffee STABLE STRICT;

CREATE TRIGGER core_models_callback_trigger 
AFTER INSERT OR UPDATE OR DELETE ON core.models
FOR EACH ROW EXECUTE PROCEDURE model_callbacks();