# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wobaduser/version'

Gem::Specification.new do |spec|
  spec.name          = "wobaduser"
  spec.version       = Wobaduser::VERSION
  spec.authors       = ["Wolfgang Barth"]
  spec.email         = ["wob@swobspace.net"]
  spec.summary       = %q{Lightweight Active Directory LDAP read access}
  spec.description   = %q{Lightweight Active Directory LDAP read access}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "net-ldap"
  spec.add_dependency "activesupport"
  spec.add_dependency "immutable-struct"

  spec.add_development_dependency "bundler", "> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "dotenv"
end
