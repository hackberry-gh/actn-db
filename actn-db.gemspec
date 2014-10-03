# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'actn/db/version'

Gem::Specification.new do |spec|
  spec.name          = "actn-db"
  spec.version       = Actn::DB::VERSION
  spec.authors       = ["Onur Uyar"]
  spec.email         = ["me@onuruyar.com"]
  spec.summary       = %q{Actn.io DB}
  spec.homepage      = "https://github.com/hackberry-gh/actn-db"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "minitest-reporters"
  
  spec.add_dependency "coffee-script"
  spec.add_dependency "em-pg-client"
  spec.add_dependency "activemodel"
  spec.add_dependency "oj"
  spec.add_dependency "bcrypt"
end
