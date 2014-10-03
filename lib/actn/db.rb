require "actn/paths"
require "actn/db/version"
require "actn/db/pg"
require "actn/db/set"
require "actn/db/mod"
require "actn/db/model"

module Actn
  
  module DB
    extend PG
    include Paths
    
    def self.gem_root
      @@gem_root ||= File.expand_path('../../../', __FILE__)
    end
    
    def self.paths
      @@paths ||= [self.gem_root]
    end
    
  end
  
end
