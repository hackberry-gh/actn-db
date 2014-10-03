-- PLV8 Functions

CREATE or REPLACE FUNCTION __json(_data json, _key text) RETURNS JSON AS $$
  ret = actn.valueAt(_data,_key) 
  return null unless ret?   
  return JSON.stringify(ret)
 
$$ LANGUAGE plcoffee STABLE STRICT;





CREATE or REPLACE FUNCTION __string(_data json, _key text) RETURNS TEXT AS $$
  ret = actn.valueAt(_data,_key) 
  return null unless ret?  
  return ret.toString()

$$ LANGUAGE plcoffee IMMUTABLE STRICT;





CREATE or REPLACE FUNCTION __integer(_data json, _key text) RETURNS INT AS $$
  ret = actn.valueAt(_data,_key) 
  return null unless ret?  
  return parseInt(ret)

$$ LANGUAGE plcoffee IMMUTABLE STRICT;





CREATE or REPLACE FUNCTION __integer_array(_data json, _key text) RETURNS INT[] AS $$
  ret = actn.valueAt(_data,_key) 
  return null unless ret?  
  return (if ret instanceof Array then ret else [ret])

$$ LANGUAGE plcoffee IMMUTABLE STRICT;





CREATE or REPLACE FUNCTION __float(_data json, _key text) RETURNS DOUBLE PRECISION AS $$
  ret = actn.valueAt(_data,_key) 
  return null unless ret?  
  return parseFloat(ret)

$$ LANGUAGE plcoffee IMMUTABLE STRICT;





CREATE or REPLACE FUNCTION __bool(_data json, _key text) RETURNS BOOLEAN AS $$
  ret = actn.valueAt(_data,_key) 
  return null unless ret?  
  return !!ret

$$ LANGUAGE plcoffee IMMUTABLE STRICT;





CREATE or REPLACE FUNCTION __timestamp(_data json, _key text) RETURNS TIMESTAMP AS $$
  ret = actn.valueAt(_data,_key) 
  return null unless ret?  
  return new Date(ret)

$$ LANGUAGE plcoffee IMMUTABLE STRICT;





CREATE or REPLACE FUNCTION __patch(_data json, _value json, _sync boolean) RETURNS JSON AS $$

  data = _data
  changes = _value
  isObject = false

  sync = if _sync? then _sync else true

  defaults = _.pick( data, _.keys( JSON.parse( plv8.find_function('__defaults')() ) ) )

  for k of changes
    if data.hasOwnProperty(k)
      isObject = typeof (data[k]) is "object" and typeof (changes[k]) is "object"
      data[k] = if isObject and sync then _.extend(data[k], changes[k]) else changes[k]
    else
      data[k] = changes[k]

  unless sync
    for k of data
      delete data[k] unless changes[k]?

  _.extend(data, defaults)

  return JSON.stringify(data)

$$ LANGUAGE plcoffee STABLE STRICT;





CREATE or REPLACE FUNCTION __select(_data json, _fields text) RETURNS JSON AS $$

  data = _data
  fields = _fields
  ret = _.pick(data,fields.split(","))
      
  return JSON.stringify(ret)
 
$$ LANGUAGE plcoffee STABLE STRICT;





CREATE or REPLACE FUNCTION __push(_data json, _key text, _value json) RETURNS JSON AS $$

  data = _data
  value = _value
  keys = _key.split(".")
  len = keys.length
  last_field = data
  field = data
  i = 0

  while i < len
    last_field = field
    field = field[keys[i]]  if field
    ++i
  if field
    field.push value
  else
    value = [value]  unless value instanceof Array
    last_field[keys.pop()] = value
    
  return JSON.stringify(data)

$$ LANGUAGE plcoffee STABLE STRICT;





CREATE or REPLACE FUNCTION __uuid() RETURNS JSON AS $$

  ary = plv8.execute 'SELECT uuid_generate_v4() as uuid;'
  return JSON.stringify(ary[0])

$$ LANGUAGE plcoffee STABLE STRICT;






CREATE or REPLACE FUNCTION __defaults() RETURNS JSON AS $$

  uuid = JSON.parse(plv8.find_function('__uuid')())
  timestamp = new Date()  
  return JSON.stringify({uuid: uuid.uuid, created_at: timestamp, updated_at: timestamp})

$$ LANGUAGE plcoffee STABLE STRICT;





CREATE or REPLACE FUNCTION __create_table(schema_name text, table_name text) RETURNS JSON AS $$

  plv8.execute """
    CREATE TABLE #{schema_name}.#{table_name} (
    id serial NOT NULL,
    data json DEFAULT __uuid() NOT NULL,
    CONSTRAINT #{schema_name}_#{table_name}_pkey PRIMARY KEY (id));
    
    CREATE UNIQUE INDEX indx_#{schema_name}_#{table_name}_unique_uuid ON #{schema_name}.#{table_name} (__string(data,'uuid'));
  """
  return JSON.stringify(table_name)
 
$$ LANGUAGE plcoffee STABLE STRICT;





CREATE or REPLACE FUNCTION __drop_table(schema_name text, table_name text) RETURNS JSON AS $$

  plv8.execute "DROP TABLE IF EXISTS #{schema_name}.#{table_name} CASCADE;"
  return JSON.stringify(table_name)
 
$$ LANGUAGE plcoffee STABLE STRICT;





CREATE or REPLACE FUNCTION __create_index(schema_name text, table_name text, optns json) RETURNS JSON AS $$

  index_name = "indx_#{schema_name}_#{table_name}"
  for name, type of optns.cols
    index_name += "_#{name}"
    
  sql = ["CREATE"]
  sql.push "UNIQUE" if optns.unique
  sql.push "INDEX"
  sql.push "CONCURRENTLY" if optns.concurrently
  sql.push "#{index_name} on #{schema_name}.#{table_name}"  
  sql.push "("  
  cols = []    
  for name, type of optns.cols
    meth = "__#{if type is 'text' then 'string' else type}"
    cols.push "#{meth}(data,'#{name}'::#{type})"
  sql.push cols.join(",")
  sql.push ")"
    
  sql = sql.join(" ")
    
  plv8.execute(sql)
  
  return JSON.stringify(index_name)
 
$$ LANGUAGE plcoffee STABLE STRICT;





CREATE or REPLACE FUNCTION __drop_index(schema_name text, table_name text, optns json) RETURNS JSON AS $$

  index_name = "indx_#{schema_name}_#{table_name}"
  for name, type of optns.cols
    index_name += "_#{name}"

  plv8.execute("DROP INDEX IF EXISTS #{index_name}")
  
  return JSON.stringify(index_name)
 
$$ LANGUAGE plcoffee STABLE STRICT;






-- ##
-- # Select data
-- # SELECT query(_schema_name, _table_name, {where: {uuid: "12345"}});

CREATE or REPLACE FUNCTION __query(_schema_name text, _table_name text, _query json) RETURNS json AS $$

  search_path = if _schema_name is "public" then _schema_name else "#{_schema_name}, public"
  
  builder = new actn.Builder(_schema_name, _table_name, search_path, _query)
  
  [sql,params] = builder.build_select()
  
  rows = plv8.execute(sql,params)
  
  builder = null  
  
  if _query?.select?.indexOf('COUNT') > -1
    result = rows
  else
    result = _.pluck(rows,'data')

  
  return JSON.stringify(result)

$$ LANGUAGE plcoffee STABLE;





-- ##
-- # Insert ot update row through validation!
-- # SELECT upsert(validate('User', '{"name":"foo"}'));

CREATE or REPLACE FUNCTION __upsert(_schema_name text, _table_name text, _data json) RETURNS json AS $$
  
  # plv8.elog(NOTICE,"UPSERT",JSON.stringify(_data))
      
  return JSON.stringify(_data) if _data.errors?
  
  data = _data
  
  search_path = if _schema_name is "public" then _schema_name else "#{_schema_name},public"

  if data.uuid?
    
    query =  { where: { uuid: data.uuid } }
    
    builder = new actn.Builder(_schema_name, _table_name, search_path, query )    
  
    [sql,params] = builder.build_update(data)

  else
    
    builder = new actn.Builder(_schema_name, _table_name, search_path, {})

    [sql,params] = builder.build_insert(data)


  # plan = plv8.prepare(sql, ['json','bool','text'])
  
  # plv8.elog(NOTICE,sql,JSON.stringify(params))
  
  rows = plv8.execute(sql, params)
  
  result = _.pluck(rows,'data')
  
  result = result[0] if result.length is 1
   
  builder = null  
  
  return JSON.stringify(result)
 
$$ LANGUAGE plcoffee STABLE STRICT;





-- ##
-- # Delete single row by uuid
-- # SELECT remove('users',uuid-1234567);

CREATE or REPLACE FUNCTION __update(_schema_name text, _table_name text, _data json, _cond json) RETURNS json AS $$

  return JSON.stringify(_data) if _data.errors?
  
  search_path = if _schema_name is "public" then _schema_name else "#{_schema_name},public"
  
  builder = new actn.Builder(_schema_name, _table_name, search_path, {where: _cond})
  
  [sql,params] = builder.build_update(_data)
  
  rows = plv8.execute(sql,params)
  result = _.pluck(rows,'data')
  result = result[0] if result.length is 1  
  
  builder = null  
  
  return JSON.stringify(result)
 
$$ LANGUAGE plcoffee STABLE STRICT;





-- ##
-- # Delete single row by uuid
-- # SELECT remove('users',uuid-1234567);

CREATE or REPLACE FUNCTION __delete(_schema_name text, _table_name text, _cond json) RETURNS json AS $$
  
  search_path = if _schema_name is "public" then _schema_name else "#{_schema_name},public"
  
  builder = new actn.Builder(_schema_name, _table_name, search_path, {where: _cond})
  
  [sql,params] = builder.build_delete()
  
  # plv8.elog(NOTICE,"DELETE",sql,params)
  
  rows = plv8.execute(sql,params)
  result = _.pluck(rows,'data')
  result = result[0] if result.length is 1
  
  builder = null  
  
  return JSON.stringify(result)
   
$$ LANGUAGE plcoffee STABLE STRICT;







-- ##
-- # Validate data by json schema
-- # SELECT validate(model_name, data);

CREATE or REPLACE FUNCTION __validate(_name text, _data json) RETURNS json AS $$

  data = _data
  
  # plv8.elog(NOTICE,"__VALIDATE",_name,JSON.stringify(_data))
  
  return data unless model = plv8.find_function('__find_model')(_name)
  
  model = JSON.parse(model)
  
  # plv8.elog(NOTICE,"__VALIDATE MODEL",_name,JSON.stringify(model))
  
  if model?.schema?
      
    errors = actn.jjv.validate(model.schema,data)
    
    plv8.elog(NOTICE,"VALVAL",JSON.stringify(model.schema))
    
    if data.uuid? and model.schema.readonly_attributes?
      
      data = _.omit(data,model.schema.readonly_attributes) 
      
      # plv8.elog(NOTICE,"VALIDATE READONLY",JSON.stringify(data),JSON.stringify(model.schema.readonly_attributes))

      
    else if model.schema.unique_attributes?
      
      _schema = if _name is "Model" then "core" else "public"
      _table = model.name.tableize()    
      __query = plv8.find_function("__query")
      
      for uniq_attr in model.schema.unique_attributes or []
        if data[uniq_attr]?
          where = {}
          where[uniq_attr] = data[uniq_attr]
          # plv8.elog(NOTICE,"VALIDATE WHERE",JSON.stringify({where: where}))
          found = JSON.parse(__query(_schema,_table,{where: where}))
          # plv8.elog(NOTICE,"VALIDATE FOUND",JSON.stringify(found))
          unless _.isEmpty(found)
            errors ?= {validation: {}}
            errors['validation'][uniq_attr] ?= {}
            errors['validation'][uniq_attr]["has already been taken"] = true
    
    data = {errors: errors} if errors?    
  
  # plv8.elog(NOTICE,"__VALIDATE DATA",_name,JSON.stringify(data))
    
  return data
 
$$ LANGUAGE plcoffee STABLE STRICT;





-- ##
-- # finds model with given name
-- # SELECT __find_model(model_name);

CREATE or REPLACE FUNCTION __find_model(_name text) RETURNS json AS $$

  rows = plv8.execute("""SET search_path TO core,public; 
  SELECT data FROM core.models 
  WHERE __string(data,'name'::text) = $1::text""", [_name])
  
  return unless rows?
  
  result = _.pluck(rows,'data')[0]
 
  return JSON.stringify(result) 
 
$$ LANGUAGE plcoffee STABLE STRICT;






