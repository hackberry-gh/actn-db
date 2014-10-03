require "actn/core_ext/kernel"
require 'pathname'

module Actn
  
  PROCFILE = "Procfile"
      
  module Paths
    
    def self.included base
      base.extend self
    end
    
    def root
      @@root ||= find_root_with_flag(PROCFILE, Dir.pwd).to_s
    end
  
    private

    # i steal this from rails
    def find_root_with_flag(flag, default=nil)
      root_path = self.called_from[0]

      while root_path && ::File.directory?(root_path) && !::File.exist?("#{root_path}/#{flag}")
        parent = ::File.dirname(root_path)
        root_path = parent != root_path && parent
      end

      root = ::File.exist?("#{root_path}/#{flag}") ? root_path : default
      raise "Could not find root path for #{self}" unless root

      RbConfig::CONFIG['host_os'] =~ /mswin|mingw/ ?
      Pathname.new(root).expand_path : Pathname.new(root).realpath
    end
    
  end
    
end 