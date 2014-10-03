class Builder
  
  constructor: (@schema_name, @table_name, @search_path, @query) ->
    @query.select ?= "*"
    @params = []
    @i = 0
  
  qm: -> "$#{@i += 1}"
  
  make_select: ->
    if @query?.select?.indexOf('COUNT') > -1
      @query.select
    else
      if @query.select is "*" 
        "data" 
      else  
        @params.push _.flatten([@query.select]).join(".")
        "__select(data, #{@qm()}) as data" #::text
  
  
  make_where: (q, join_by = 'AND') ->
    sql = []
    for k, subquery of q
      switch k
        when 'and', 'AND', '&', '&&'
          sql.push "(#{make_where(subquery, 'AND')})"
        when  'or',  'OR', '|', '||'
          sql.push "(#{make_where(subquery, 'OR')})"
        when 'not', 'NOT', '!'
          sql.push "NOT (#{make_where(subquery, 'AND')})"
        else
          if _.isArray(subquery)
            @params.push k
            @params.push subquery[1]
            sql.push "#{@plv8_key(subquery[1])} #{subquery[0]} #{@plv8_qm(subquery[1])}"
          else if _.isObject(subquery)
            comparisons = []
            for symbol, value in subquery
              comparisons.push "#{symbol} #{@plv8_qm(value)}"
              @params.push k                    
              @params.push value
            sql.push _.map(comparisons, (comparison) -> "#{@plv8_key(value)} #{comparison}").join(" AND ")
          else
            @params.push k
            @params.push subquery
            sql.push "#{@plv8_key(subquery)} = #{@plv8_qm(subquery)}"

    sql.join "\n#{join_by} "

  
  make_order_by: () ->
    ord = @query.order_by
    str = []
    if _.isArray(ord)
      @params.push ord[0]
      str.push "#{@plv8_key(ord[1])} #{ord[1].toUpperCase()}"
    else if _.isObject(ord)
      for k,v in ord
        @params.push v
        str.push "#{@plv8_key(k)} #{k.toUpperCase()}"
    else
      @params.push ord
      str.push @qm()
    str.join(",")  
  
  
  make_limit: ->
    @params.push @query.limit
    @qm()


  make_offset: ->
    @params.push @query.offset
    @qm()
    

  build_select: ->
    sql = []
    sql.push "SET search_path TO #{@search_path};"
    sql.push "SELECT #{@make_select()} FROM #{@schema_name}.#{@table_name}"
    sql.push "WHERE #{@make_where(@query.where)}" unless _.isEmpty(@query.where)
    sql.push "ORDER BY #{@make_order()}" if @query.order_by?
    sql.push "LIMIT #{@make_limit()}" if @query.limit?
    sql.push "OFFSET #{@make_offset()}" if @query.offset?
    [sql.join("\n"), @params]

  build_delete: ->
    sql = []
    sql.push "SET search_path TO #{@search_path};"
    sql.push "DELETE FROM #{@schema_name}.#{@table_name}"
    sql.push "WHERE #{@make_where(@query.where)}" unless _.isEmpty(@query.where)
    sql.push "RETURNING data::json;"
    [sql.join("\n"), @params]
    
  build_update: (data, merge = true) ->
    
    @params.push data
    @params.push merge
    sql = []
    sql.push "SET search_path TO #{@search_path};"
    sql.push "UPDATE #{@schema_name}.#{@table_name} SET data = __patch(data,#{@qm()},#{@qm()})"
    sql.push "WHERE #{@make_where(@query.where)}" unless _.isEmpty(@query.where)
    sql.push "RETURNING data::json;"    
    [sql.join("\n"), @params]  
  
  build_insert: (data, merge = true) ->
    @params.push data
    @params.push merge
    sql = []
    sql.push "SET search_path TO #{@search_path};" 
    sql.push "INSERT INTO #{@schema_name}.#{@table_name} (data) VALUES (__patch(__defaults(),#{@qm()},#{@qm()}))"
    sql.push "RETURNING data::json;"
    [sql.join("\n"), @params] 

  plv8_key: (value) -> "#{@typecast(value,true)}(data, #{@qm()}::text)" #::text

  plv8_qm: (value) -> "#{@qm()}::#{@typecast(value)}"
    
  typecast: (value, is_func = false) ->
    type = if is_func then "__" else ""
    if _.isBoolean(value)
      type += "bool"
    else if _.isDate(value)
      type += "timestamp"
    else if _.isNumber(value)  
      type += "integer"
    else if _.isObject(value)
      type += (if is_func then "text" else "json")
    else if _.isArray(value)
      type += (if is_func then "text" else "array")
    else
      type += (if is_func then "string" else "text")
    type


actn.Builder = Builder
