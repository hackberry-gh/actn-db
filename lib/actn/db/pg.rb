require 'oj'
require 'uri'
require 'pg/em'
require 'pg/em/connection_pool'
require 'active_support/inflector'
require 'actn/core_ext/hash'
require 'actn/core_ext/string'

module Actn
  module DB
    module PG
      
      class JsonSchemaError < StandardError
        def initialize payload
          # puts " PAYLOAD #{payload}"
          @errors = Oj.load(payload)['errors']['validation']
        end
        def errors  
          @errors
        end
      end
      
      Oj.default_options = { time_format: :ruby, mode: :compat }
    
      def inspect_func func_name, *params
        sql = "SELECT __#{func_name}(#{ (params.length-1).times.inject("$1"){ |m,i| "#{m},$#{ i + 2 }"} })"
        [sql, params]
      end
    
      def exec_func func_name, *params
        sql = "SELECT __#{func_name}(#{ (params.length-1).times.inject("$1"){ |m,i| "#{m},$#{ i + 2 }"} })"
        # exec_prepared "#{sql.parameterize.underscore}_#{params[0..1].join("_")}", sql, params
        exec_params sql, params
      end
    
      def exec_prepared statement, sql, params = []
        pg.prepare statement, sql rescue ::PG::DuplicatePstatement
        puts "PREPARED ---> #{statement}" 
        puts sql.inspect, params.inspect
        puts "<<<<<---------------------"
        begin          
          result = pg.exec_prepared(statement, params)
          json = result.values.flatten.first
          result.clear
          json
        rescue ::PG::InvalidSqlStatementName
          exec_params sql, params
        end
        
      end
    
      def exec_params sql, params = []
        result = pg.exec_params(sql, params)
        json = result.values.flatten.first
        result.clear
        json
      end
    
      ##
      # :singleton method
      # holds db connection

      def pg 
        @@connection_pool ||= ::PG::EM::ConnectionPool.new(db_config)
      end
      
      
      ##
      # :singleton method
      # parses database url
      
      def db_config
        @@config ||= begin
          db = URI.parse(ENV['DATABASE_URL'])
          config = {
            dbname: db.path[1..-1],
            host: db.host,
            port: db.port,
            size: ENV['DB_POOL_SIZE'] || 5,          
            async_autoreconnect: ENV['DB_ASYNC_AUTO_RECONNECT'] || true,
            connect_timeout: ENV['DB_CONN_TIMEOUT'] || 60,
            query_timeout: ENV['DB_QUERY_TIMEOUT'] || 30,
            on_autoreconnect: proc { |pg| pg.exec "SELECT plv8_startup();" rescue nil },
            on_connect: proc { |pg| pg.exec "SELECT plv8_startup();" rescue nil }
          }
          config[:user] = db.user if db.user
          config[:password] = db.password if db.password
          config
        end
      end
    
    end
  
  end
end