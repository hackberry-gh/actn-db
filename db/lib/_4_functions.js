// Generated by CoffeeScript 1.6.3
(function() {
  var Funcs, root;
  root = this;
  Funcs = (function() {
    function Funcs() {}

    Funcs.prototype.__json = function(_data, _key) {
      var ret;
      ret = actn.valueAt(_data, _key);
      if (ret == null) {
        return null;
      }
      return JSON.stringify(ret);
    };

    Funcs.prototype.__string = function(_data, _key) {
      var ret;
      ret = actn.valueAt(_data, _key);
      if (ret == null) {
        return null;
      }
      return ret.toString();
    };

    Funcs.prototype.__integer = function(_data, _key) {
      var ret;
      ret = actn.valueAt(_data, _key);
      if (ret == null) {
        return null;
      }
      return parseInt(ret);
    };

    Funcs.prototype.__integer_array = function(_data, _key) {
      var ret;
      ret = actn.valueAt(_data, _key);
      if (ret == null) {
        return null;
      }
      return (ret instanceof Array ? ret : [ret]);
    };

    Funcs.prototype.__float = function(_data, _key) {
      var ret;
      ret = actn.valueAt(_data, _key);
      if (ret == null) {
        return null;
      }
      return parseFloat(ret);
    };

    Funcs.prototype.__bool = function(_data, _key) {
      var ret;
      ret = actn.valueAt(_data, _key);
      if (ret == null) {
        return null;
      }
      return !!ret;
    };

    Funcs.prototype.__timestamp = function(_data, _key) {
      var ret;
      ret = actn.valueAt(_data, _key);
      if (ret == null) {
        return null;
      }
      return new Date(ret);
    };

    Funcs.prototype.__patch = function(_data, _value, _sync) {
      var changes, data, defaults, isObject, k, sync;
      data = _data;
      changes = _value;
      isObject = false;
      sync = _sync != null ? _sync : true;
      defaults = _.pick(data, _.keys(JSON.parse(plv8.find_function('__defaults')())));
      for (k in changes) {
        if (data.hasOwnProperty(k)) {
          isObject = typeof data[k] === "object" && typeof changes[k] === "object";
          data[k] = isObject && sync ? _.extend(data[k], changes[k]) : changes[k];
        } else {
          data[k] = changes[k];
        }
      }
      if (!sync) {
        for (k in data) {
          if (changes[k] == null) {
            delete data[k];
          }
        }
      }
      _.extend(data, defaults);
      return JSON.stringify(data);
    };

    Funcs.prototype.__select = function(_data, _fields) {
      var data, fields, ret;
      data = _data;
      fields = _fields;
      ret = _.pick(data, fields.split(","));
      return JSON.stringify(ret);
    };

    Funcs.prototype.__push = function(_data, _key, _value) {
      var data, field, i, keys, last_field, len, value;
      data = _data;
      value = _value;
      keys = _key.split(".");
      len = keys.length;
      last_field = data;
      field = data;
      i = 0;
      while (i < len) {
        last_field = field;
        if (field) {
          field = field[keys[i]];
        }
        ++i;
      }
      if (field) {
        field.push(value);
      } else {
        if (!(value instanceof Array)) {
          value = [value];
        }
        last_field[keys.pop()] = value;
      }
      return JSON.stringify(data);
    };

    Funcs.prototype.__uuid = function() {
      var ary;
      ary = plv8.execute('SELECT uuid_generate_v4() as uuid;');
      return JSON.stringify(ary[0]);
    };

    Funcs.prototype.__defaults = function() {
      var timestamp, uuid;
      uuid = JSON.parse(plv8.find_function('__uuid')());
      timestamp = new Date();
      return JSON.stringify({
        uuid: uuid.uuid,
        created_at: timestamp,
        updated_at: timestamp
      });
    };

    Funcs.prototype.__create_table = function(schema_name, table_name) {
      plv8.execute("      CREATE TABLE " + schema_name + "." + table_name + " (\n      id serial NOT NULL,\n      data json DEFAULT __uuid() NOT NULL,\n      CONSTRAINT " + schema_name + "_" + table_name + "_pkey PRIMARY KEY (id));\n\n      CREATE UNIQUE INDEX indx_" + schema_name + "_" + table_name + "_unique_uuid ON " + schema_name + "." + table_name + " (__string(data,'uuid'));");
      return JSON.stringify(table_name);
    };

    Funcs.prototype.__drop_table = function(schema_name, table_name) {
      plv8.execute("DROP TABLE IF EXISTS " + schema_name + "." + table_name + " CASCADE;");
      return JSON.stringify(table_name);
    };

    Funcs.prototype.__create_index = function(schema_name, table_name, optns) {
      var cols, index_name, meth, name, sql, type, _ref, _ref1;
      index_name = "indx_" + schema_name + "_" + table_name;
      _ref = optns.cols;
      for (name in _ref) {
        type = _ref[name];
        index_name += "_" + name;
      }
      sql = ["CREATE"];
      if (optns.unique) {
        sql.push("UNIQUE");
      }
      sql.push("INDEX");
      if (optns.concurrently) {
        sql.push("CONCURRENTLY");
      }
      sql.push("" + index_name + " on " + schema_name + "." + table_name);
      sql.push("(");
      cols = [];
      _ref1 = optns.cols;
      for (name in _ref1) {
        type = _ref1[name];
        meth = "__" + (type === 'text' ? 'string' : type);
        cols.push("" + meth + "(data,'" + name + "'::" + type + ")");
      }
      sql.push(cols.join(","));
      sql.push(")");
      sql = sql.join(" ");
      plv8.execute(sql);
      return JSON.stringify(index_name);
    };

    Funcs.prototype.__drop_index = function(schema_name, table_name, optns) {
      var index_name, name, type, _ref;
      index_name = "indx_" + schema_name + "_" + table_name;
      _ref = optns.cols;
      for (name in _ref) {
        type = _ref[name];
        index_name += "_" + name;
      }
      plv8.execute("DROP INDEX IF EXISTS " + index_name);
      return JSON.stringify(index_name);
    };

    Funcs.prototype.__query = function(_schema_name, _table_name, _query) {
      var builder, params, result, rows, search_path, sql, _ref, _ref1;
      search_path = _schema_name === "public" ? _schema_name : "" + _schema_name + ", public";
      builder = new actn.Builder(_schema_name, _table_name, search_path, _query);
      _ref = builder.build_select(), sql = _ref[0], params = _ref[1];
      rows = plv8.execute(sql, params);
      builder = null;
      if ((_query != null ? (_ref1 = _query.select) != null ? _ref1.indexOf('COUNT') : void 0 : void 0) > -1) {
        result = rows;
      } else {
        result = _.pluck(rows, 'data');
      }
      return JSON.stringify(result);
    };

    Funcs.prototype.__upsert = function(_schema_name, _table_name, _data) {
      var builder, data, params, query, result, rows, search_path, sql, _ref, _ref1;
      if (_data.errors != null) {
        return JSON.stringify(_data);
      }
      data = _data;
      search_path = _schema_name === "public" ? _schema_name : "" + _schema_name + ",public";
      if (data.uuid != null) {
        query = {
          where: {
            uuid: data.uuid
          }
        };
        builder = new actn.Builder(_schema_name, _table_name, search_path, query);
        _ref = builder.build_update(data), sql = _ref[0], params = _ref[1];
      } else {
        builder = new actn.Builder(_schema_name, _table_name, search_path, {});
        _ref1 = builder.build_insert(data), sql = _ref1[0], params = _ref1[1];
      }
      rows = plv8.execute(sql, params);
      result = _.pluck(rows, 'data');
      if (result.length === 1) {
        result = result[0];
      }
      builder = null;
      return JSON.stringify(result);
    };

    Funcs.prototype.__update = function(_schema_name, _table_name, _data, _cond) {
      var builder, params, result, rows, search_path, sql, _ref;
      if (_data.errors != null) {
        return JSON.stringify(_data);
      }
      search_path = _schema_name === "public" ? _schema_name : "" + _schema_name + ",public";
      builder = new actn.Builder(_schema_name, _table_name, search_path, {
        where: _cond
      });
      _ref = builder.build_update(_data), sql = _ref[0], params = _ref[1];
      rows = plv8.execute(sql, params);
      result = _.pluck(rows, 'data');
      if (result.length === 1) {
        result = result[0];
      }
      builder = null;
      return JSON.stringify(result);
    };

    Funcs.prototype.__delete = function(_schema_name, _table_name, _cond) {
      var builder, params, result, rows, search_path, sql, _ref;
      search_path = _schema_name === "public" ? _schema_name : "" + _schema_name + ",public";
      builder = new actn.Builder(_schema_name, _table_name, search_path, {
        where: _cond
      });
      _ref = builder.build_delete(), sql = _ref[0], params = _ref[1];
      rows = plv8.execute(sql, params);
      result = _.pluck(rows, 'data');
      if (result.length === 1) {
        result = result[0];
      }
      builder = null;
      return JSON.stringify(result);
    };

    Funcs.prototype.__validate = function(_name, _data) {
      var data, errors, found, model, uniq_attr, where, __query, _base, _i, _len, _ref, _schema, _table;
      data = _data;
      if (!(model = plv8.find_function('__find_model')(_name))) {
        return data;
      }
      model = JSON.parse(model);
      if ((model != null ? model.schema : void 0) != null) {
        errors = actn.jjv.validate(model.schema, data);
        if ((data.uuid != null) && (model.schema.readonly_attributes != null)) {
          data = _.omit(data, model.schema.readonly_attributes);
        } else if (model.schema.unique_attributes != null) {
          _schema = _name === "Model" ? "core" : "public";
          _table = model.name.tableize();
          __query = plv8.find_function("__query");
          _ref = model.schema.unique_attributes || [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            uniq_attr = _ref[_i];
            if (data[uniq_attr] != null) {
              where = {};
              where[uniq_attr] = data[uniq_attr];
              found = JSON.parse(__query(_schema, _table, {
                where: where
              }));
              if (!_.isEmpty(found)) {
                if (errors == null) {
                  errors = {
                    validation: {}
                  };
                }
                if ((_base = errors['validation'])[uniq_attr] == null) {
                  _base[uniq_attr] = {};
                }
                errors['validation'][uniq_attr]["has already been taken"] = true;
              }
            }
          }
        }
        if (errors != null) {
          data = {
            errors: errors
          };
        }
      }
      return data;
    };

    Funcs.prototype.__find_model = function(_name) {
      var result, rows;
      rows = plv8.execute("SET search_path TO core,public; \nSELECT data FROM core.models \nWHERE __string(data,'name'::text) = $1::text", [_name]);
      if (rows == null) {
        return;
      }
      result = _.pluck(rows, 'data')[0];
      return JSON.stringify(result);
    };

    Funcs.prototype.model_callbacks = function(TG_OP, NEW, OLD) {
      var diff, differ, indopts, mapper, table_name, table_schema, _i, _j, _k, _l, _len, _len1, _len2, _len3, _ref, _ref1, _ref10, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9, _results, _results1;
      table_name = (_ref = (NEW != null ? (_ref1 = NEW.data) != null ? _ref1.name : void 0 : void 0) || (OLD != null ? (_ref2 = OLD.data) != null ? _ref2.name : void 0 : void 0)) != null ? _ref.tableize() : void 0;
      table_schema = ((NEW != null ? (_ref3 = NEW.data) != null ? _ref3.table_schema : void 0 : void 0) || (OLD != null ? (_ref4 = OLD.data) != null ? _ref4.table_schema : void 0 : void 0)) || "public";
      if (table_schema === "core") {
        return;
      }
      mapper = function(ind) {
        return _.keys(ind.cols);
      };
      differ = function(_ind) {
        return function(ind) {
          var _ref5;
          return _.isEmpty(_.difference(_.keys(ind.cols), _.flatten(_.map((_ref5 = _ind.data) != null ? _ref5.indexes : void 0, mapper))));
        };
      };
      switch (TG_OP) {
        case "INSERT":
          plv8.execute("SELECT __create_table($1,$2)", [table_schema, table_name]);
          plv8.execute("SELECT __create_index($1,$2,$3)", [
            table_schema, table_name, {
              cols: {
                path: "text"
              }
            }
          ]);
          _ref6 = (NEW != null ? (_ref5 = NEW.data) != null ? _ref5.indexes : void 0 : void 0) || [];
          _results = [];
          for (_i = 0, _len = _ref6.length; _i < _len; _i++) {
            indopts = _ref6[_i];
            _results.push(plv8.execute("SELECT __create_index($1,$2,$3)", [table_schema, table_name, indopts]));
          }
          return _results;
          break;
        case "UPDATE":
          diff = _.reject(OLD != null ? (_ref7 = OLD.data) != null ? _ref7.indexes : void 0 : void 0, differ(NEW));
          for (_j = 0, _len1 = diff.length; _j < _len1; _j++) {
            indopts = diff[_j];
            plv8.execute("SELECT __drop_index($1,$2,$3)", [table_schema, table_name, indopts]);
          }
          diff = _.reject(NEW != null ? (_ref8 = NEW.data) != null ? _ref8.indexes : void 0 : void 0, differ(OLD));
          _results1 = [];
          for (_k = 0, _len2 = diff.length; _k < _len2; _k++) {
            indopts = diff[_k];
            _results1.push(plv8.execute("SELECT __create_index($1,$2,$3)", [table_schema, table_name, indopts]));
          }
          return _results1;
          break;
        case "DELETE":
          _ref10 = (typeof Old !== "undefined" && Old !== null ? (_ref9 = Old.data) != null ? _ref9.indexes : void 0 : void 0) || [];
          for (_l = 0, _len3 = _ref10.length; _l < _len3; _l++) {
            indopts = _ref10[_l];
            plv8.execute("SELECT __drop_index($1,$2,$3)", [table_schema, table_name, indopts]);
          }
          return plv8.execute("SELECT __drop_table($1,$2)", [table_schema, table_name]);
      }
    };

    Funcs.prototype.hook_trigger = function(TG_TABLE_NAME, TG_OP, NEW, OLD) {
      var callback, hook, job, model, res, upsert_func, _i, _len, _ref, _ref1, _ref2, _ref3, _results;
      upsert_func = plv8.find_function("__upsert");
      model = JSON.parse(plv8.find_function("__find_model")(TG_TABLE_NAME.classify()));
      callback = {
        INSERT: "after_create",
        UPDATE: "after_update",
        DELETE: "after_destroy"
      }[TG_OP];
      _ref1 = (model != null ? (_ref = model.hooks) != null ? _ref[callback] : void 0 : void 0) || [];
      _results = [];
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        hook = _ref1[_i];
        if (hook.run_at == null) {
          hook.run_at = new Date();
        }
        hook.callback = callback;
        job = {
          hook: hook,
          table_name: TG_TABLE_NAME,
          record_uuid: (NEW != null ? (_ref2 = NEW.data) != null ? _ref2.uuid : void 0 : void 0) || (OLD != null ? (_ref3 = OLD.data) != null ? _ref3.uuid : void 0 : void 0),
          record: TG_OP === "DELETE" ? OLD.data : void 0
        };
        res = upsert_func("core", "jobs", JSON.stringify(job));
        _results.push(plv8.execute("SELECT pg_notify('jobs', $1);", [res]));
      }
      return _results;
    };

    Funcs.prototype.jobs_model_callbacks = function(TG_TABLE_NAME, TG_OP, NEW, OLD) {
      var table_name, table_schema, _ref, _ref1, _ref2, _ref3;
      table_name = ((NEW != null ? (_ref = NEW.data) != null ? _ref.name : void 0 : void 0) || (OLD != null ? (_ref1 = OLD.data) != null ? _ref1.name : void 0 : void 0)).tableize();
      table_schema = ((NEW != null ? (_ref2 = NEW.data) != null ? _ref2.table_schema : void 0 : void 0) || (OLD != null ? (_ref3 = OLD.data) != null ? _ref3.table_schema : void 0 : void 0)) || "public";
      if (table_schema === "core") {
        return;
      }
      if (TG_OP === "DELETE") {
        plv8.execute("DELETE FROM core.jobs WHERE __string(data, 'table_name'::text) = $1;", [table_name]);
      }
      if (TG_OP === "INSERT" || TG_OP === "UPDATE" && (NEW.data.hooks != null) && (OLD.data.hooks == null)) {
        return plv8.execute("CREATE TRIGGER " + table_schema + "_" + table_name + "_hook_trigger \nAFTER INSERT OR UPDATE OR DELETE ON " + table_schema + "." + table_name + " \nFOR EACH ROW EXECUTE PROCEDURE hook_trigger();");
      }
    };

    return Funcs;

  })();
  return root.actn.funcs = new Funcs;
}).call(this);
