require 'actn/db/pg'

module Actn
  module DB
    class Set
      
      include PG
      
      def self.tables
        @@tables ||= {}
      end
      
      def self.[]table
        self.tables[table] ||= new(:public,table)
      end
      
      attr_accessor :table, :schema
      
      def initialize schema, table
        self.table = table
        self.schema = schema
      end

      # where(:not => { active: :true }, :or => { name: { :== => 'Igor'}, age: { :>= => 20 } })
      
      [:query,:upsert, :update, :delete].each do |meth|
        class_eval <<-CODE
        def #{meth} *args
          exec_func :#{meth}, schema, table, *args.map(&:to_json)
        end
        CODE
      end
      
      [:query].each do |meth|
        class_eval <<-CODE
        def inspect_#{meth} *args
          inspect_func :#{meth}, schema, table, *args.map(&:to_json)
        end
        CODE
      end
      
      def validate_and_upsert data
        sql = "SELECT __upsert($1,$2,__validate($3,$4))"
        # exec_prepared "#{sql.parameterize.underscore}_#{schema}_#{table}_#{data.keys.join('_')}", sql, [schema, table, table.classify, data.to_json]
        exec_params sql, [schema, table, table.classify, data.to_json]
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