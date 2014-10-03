require 'actn/db/pg'

module Actn
  module DB
    class Set
      
      include PG
      
      def self.tables
        @@tables ||= {}
      end
      
      def self.[]table
        self.tables[table] ||= new(table)
      end
      
      attr_accessor :table, :schema
      
      def initialize schema = :public, table
        self.table = table
        self.schema = schema
      end

      
      [:query,:upsert, :update, :delete].each do |meth|
        class_eval <<-CODE
        def #{meth} *args
          exec_func :#{meth}, schema, table, *args.map(&:to_json)
        end
        CODE
      end
      
      def validate_and_upsert data
        sql = "SELECT __upsert($1,$2,__validate($3,$4))"
        exec_prepared sql.parameterize.underscore, sql, [schema, table, table.classify, data.to_json]
      end

      
      def count conds = {}
        exec_func :query, schema, table, {select: 'COUNT(id)'}.merge(conds).to_json
      end
      
      
      def all
        where({})
      end
      
      def where cond
        query({where: cond})        
      end
      
      def find_by cond
        query({where: cond,limit: 1})[1..-2]
      end
      
      def find uuid
        find_by(uuid: uuid)
      end
      
      def delete_all
        delete({})
      end
      
    
    end
  end
end