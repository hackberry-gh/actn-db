require 'actn/db/pg'
require 'actn/db/set'
require "active_model"


module Actn
  module DB
    class Mod
      
      include PG
      
      include ActiveModel::Model
      extend ActiveModel::Callbacks
      include ActiveModel::Validations
      include ActiveModel::Validations::Callbacks
      include ActiveModel::Serializers::JSON

      define_model_callbacks :create
      define_model_callbacks :update
      define_model_callbacks :destroy
      
      class << self
    
        attr_accessor :schema, :table, :set
        
        def set
          @set ||= Set.new(schema, table)
        end
        
        def data_attr_accessor *fields
          fields.each do |field|
            class_eval %Q{ 
              def #{field}; self.attributes['#{field}'] end
              def #{field}=val; self.attributes['#{field}']=val end
            }
          end 
        end
        
        def create data = {}
          record = new(data)
          record.save
          record
        end
        
        [:validate_and_upsert, :upsert, :update, :delete, :delete_all].each do |meth|
          class_eval <<-RUBY
          def #{meth} *args
            set.#{meth}(*args)
          end
          RUBY
        end
        
        [:find_by, :find].each do |meth|
          class_eval <<-RUBY
          def #{meth} conds
            return nil if conds.empty?
            new.from_json(set.#{meth}(conds)) rescue nil
          end
          RUBY
        end
        
        [:all, :where].each do |meth|
          class_eval <<-RUBY
          def #{meth} *args
            (Oj.load(set.#{meth}(*args)) rescue {}).map{ |attrs| new(attrs) }
          end
          RUBY
        end
        
        def count conds = {}
          set.count(conds).match(/(\d+)/)[1].to_i
        end
      
      end
      
      self.schema ||= "public"
      
      attr_accessor :attributes
      data_attr_accessor :uuid, :locale, :created_at, :updated_at
      
      
      def initialize data = {}
        data ||= {}
        register_attr_accessors data
        super(data)
      end

      def attributes
        @attributes ||= {}
      end

      def persisted?
        self.uuid.present?
      end

      def uuid
        self.attributes['uuid']
      end

      ##
      # persistency

      def save
        create_or_update if valid?
      end

      def update attrs
        register_attr_accessors attrs        
        self.attributes.update(attrs)
        save
      end

      def destroy
        return unless self.persisted?
        run_callbacks :destroy do
          if result = self.class.delete(identity)
            process_upsert_response result
          end
        end
      end


      private

      def create_or_update
        self.persisted? ? _update : _insert
      end

      def _update
        run_callbacks :update do        
          # if result = self.class.update(self.attributes,identity)
          if result = self.class.validate_and_upsert(self.attributes.merge(identity))          
            process_upsert_response result
          end
        end
      end

      def _insert
        run_callbacks :create do
          if result = self.class.validate_and_upsert(self.attributes)
            process_upsert_response result
          end
        end
      end

      def identity
        {'uuid' => self.uuid}
      end
    
      ##
      # allows dynamic attributes! 
    
      def register_attr_accessors data
        data.deep_stringify_keys!
        # ignore attributes declared with attr_accessor method
        self.class.data_attr_accessor *data.keys.keep_if{ |key| 
          public_methods.keep_if{ |n| n.to_s.start_with? key }.empty? 
        }
      end
      
      private
      
      def process_upsert_response result
        if result =~ /uuid/
          self.from_json(result)            
        elsif result =~ /error/
          JsonSchemaError.new(result).errors.each do |field,err|
            errors.add(field,err.keys.flatten.join(","))            
          end
          return false
        end
        self
      end
    
    end
  end
end