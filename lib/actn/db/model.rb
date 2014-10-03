require 'actn/db/mod'
require 'active_support/inflector'

module Actn
  module DB
    class Model < Mod
        
      self.table = "models"
      self.schema = "core" 
      
      data_attr_accessor :table_schema, :name, :indexes, :schema, :hooks
      
      before_create :classify_name
      before_update :classify_name      
      
      private
      
      def classify_name
        self.name = self.name.classify if self.name
      end
      
     
    end
  end
end