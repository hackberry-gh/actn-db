-- PLV8 Functions

CREATE or REPLACE FUNCTION __json(_data json, _key text) RETURNS JSON AS $$
  return actn.funcs.__json(_data, _key);
$$ LANGUAGE plv8 IMMUTABLE STRICT;



CREATE or REPLACE FUNCTION __string(_data json, _key text) RETURNS TEXT AS $$
  return actn.funcs.__string(_data, _key);
$$ LANGUAGE plv8 IMMUTABLE STRICT;



CREATE or REPLACE FUNCTION __integer(_data json, _key text) RETURNS INT AS $$
  return actn.funcs.__integer(_data, _key);
$$ LANGUAGE plv8 IMMUTABLE STRICT;



CREATE or REPLACE FUNCTION __integer_array(_data json, _key text) RETURNS INT[] AS $$
  return actn.funcs.__integer_array(_data, _key);
$$ LANGUAGE plv8 IMMUTABLE STRICT;



CREATE or REPLACE FUNCTION __float(_data json, _key text) RETURNS DOUBLE PRECISION AS $$
  return actn.funcs.__float(_data, _key);
$$ LANGUAGE plv8 IMMUTABLE STRICT;



CREATE or REPLACE FUNCTION __bool(_data json, _key text) RETURNS BOOLEAN AS $$
  return actn.funcs.__bool(_data, _key);
$$ LANGUAGE plv8 IMMUTABLE STRICT;



CREATE or REPLACE FUNCTION __timestamp(_data json, _key text) RETURNS TIMESTAMP AS $$
  return actn.funcs.__timestamp(_data, _key);
$$ LANGUAGE plv8 IMMUTABLE STRICT;



CREATE or REPLACE FUNCTION __select(_data json, _fields text) RETURNS JSON AS $$
  return actn.funcs.__select(_data, _fields); 
$$ LANGUAGE plv8 STABLE STRICT;



CREATE or REPLACE FUNCTION __patch(_data json, _value json, _sync boolean) RETURNS JSON AS $$
  return actn.funcs.__patch(_data, _value, _sync);
$$ LANGUAGE plv8 VOLATILE STRICT;



CREATE or REPLACE FUNCTION __push(_data json, _key text, _value json) RETURNS JSON AS $$
  return actn.funcs.__push(_data, _key, _value);
$$ LANGUAGE plv8 VOLATILE STRICT;



CREATE or REPLACE FUNCTION __uuid() RETURNS JSON AS $$
  return actn.funcs.__uuid();  
$$ LANGUAGE plv8 VOLATILE STRICT;



CREATE or REPLACE FUNCTION __defaults() RETURNS JSON AS $$
  return actn.funcs.__defaults();
$$ LANGUAGE plv8 VOLATILE STRICT;



CREATE or REPLACE FUNCTION __create_table(schema_name text, table_name text) RETURNS void AS $$
  try{
    actn.funcs.__create_table(schema_name, table_name);  
  } catch(e) {
    plv8.elog( NOTICE, "---> ERROR ON __create_table(" + schema_name + "," + table_name + ")")
  }  
$$ LANGUAGE plv8 VOLATILE STRICT;



CREATE or REPLACE FUNCTION __drop_table(schema_name text, table_name text) RETURNS void AS $$
  actn.funcs.__drop_table(schema_name, table_name); 
$$ LANGUAGE plv8 VOLATILE STRICT;



CREATE or REPLACE FUNCTION __create_index(schema_name text, table_name text, optns json) RETURNS void AS $$
  actn.funcs.__create_index(schema_name, table_name, optns);
$$ LANGUAGE plv8 VOLATILE STRICT;



CREATE or REPLACE FUNCTION __drop_index(schema_name text, table_name text, optns json) RETURNS void AS $$
  actn.funcs.__drop_index(schema_name, table_name, optns);  
$$ LANGUAGE plv8 VOLATILE STRICT;



-- ##
-- # Select data
-- # SELECT query(_schema_name, _table_name, {where: {uuid: "12345"}});

CREATE or REPLACE FUNCTION __query(_schema_name text, _table_name text, _query json) RETURNS json AS $$
  return actn.funcs.__query(_schema_name, _table_name, _query);
$$ LANGUAGE plv8 STABLE STRICT;



-- ##
-- # Insert ot update row through validation!
-- # SELECT upsert(validate('User', '{"name":"foo"}'));

CREATE or REPLACE FUNCTION __upsert(_schema_name text, _table_name text, _data json) RETURNS json AS $$
  return actn.funcs.__upsert(_schema_name, _table_name, _data); 
$$ LANGUAGE plv8 VOLATILE STRICT;



-- ##
-- # Delete single row by uuid
-- # SELECT remove('users',uuid-1234567);

CREATE or REPLACE FUNCTION __update(_schema_name text, _table_name text, _data json, _cond json) RETURNS json AS $$
  return actn.funcs.__update(_schema_name, _table_name, _data, _cond);   
$$ LANGUAGE plv8 VOLATILE STRICT;



-- ##
-- # Delete single row by uuid
-- # SELECT remove('users',uuid-1234567);

CREATE or REPLACE FUNCTION __delete(_schema_name text, _table_name text, _cond json) RETURNS json AS $$
  return actn.funcs.__delete(_schema_name, _table_name, _cond);     
$$ LANGUAGE plv8 VOLATILE STRICT;



-- ##
-- # Validate data by json schema
-- # SELECT validate(model_name, data);

CREATE or REPLACE FUNCTION __validate(_name text, _data json) RETURNS json AS $$
  return actn.funcs.__validate(_name, _data);    
$$ LANGUAGE plv8 VOLATILE STRICT;



-- ##
-- # finds model with given name
-- # SELECT __find_model(model_name);

CREATE or REPLACE FUNCTION __find_model(_name text) RETURNS json AS $$
  return actn.funcs.__find_model(_name);   
$$ LANGUAGE plv8 STABLE STRICT;
