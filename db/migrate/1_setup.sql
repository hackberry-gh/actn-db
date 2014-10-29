-- Extensions

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "plv8";




-- Js Libs
DROP TABLE IF EXISTS public.plv8_modules;

CREATE TABLE plv8_modules(name text primary key, code text);

CREATE OR REPLACE FUNCTION plv8_startup() RETURNS void AS $$
  
  var code, r, rows;

  code = "";
  
  rows = plv8.execute("SELECT name, code FROM public.plv8_modules ORDER BY name");

  r = 0;

  while (r < rows.length) {
    code += rows[r].code;
    r++;
  }
  
  eval("(function(){" + code + "})")();  
    
$$ LANGUAGE plv8 STABLE STRICT;