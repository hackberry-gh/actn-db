-- Extensions

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "plv8";




-- Js Libs

CREATE TABLE plv8_modules(modname text primary key, load_on_start boolean, code text);

CREATE OR REPLACE FUNCTION plv8_startup() RETURNS void AS $$
  
  var code, r, rows;

  code = "";
  
  rows = plv8.execute("SELECT modname, code from public.plv8_modules order by modname");

  r = 0;

  while (r < rows.length) {
    code += rows[r].code;
    r++;
  }
  
  eval("(function(){" + code + "})")();  
    
$$ LANGUAGE plv8 STABLE STRICT;