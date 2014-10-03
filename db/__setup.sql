-- Extensions

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "plv8";





-- Js Libs

CREATE TABLE plv8_modules(modname text primary key, load_on_start boolean, code text);

CREATE OR REPLACE FUNCTION plv8_startup() RETURNS void AS $$
  
  var code, load_module, r, rows;

  load_module = function(modname) {
    var code, r, rows;
    rows = plv8.execute("SELECT code from public.plv8_modules " + " where modname = $1", [modname]);
    r = 0;
    while (r < rows.length) {
      code = rows[r].code;
      eval("(function(){" + code + "})")();
      r++;
    }
  };

  rows = plv8.execute("SELECT modname, code from public.plv8_modules where load_on_start");

  r = 0;

  while (r < rows.length) {
    code = rows[r].code;
    eval("(function(){" + code + "})")();
    r++;
  }
    
$$ LANGUAGE plv8 STABLE STRICT;