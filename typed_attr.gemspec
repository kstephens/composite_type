# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'typed_attr/version'

Gem::Specification.new do |spec|
  spec.name          = "typed_attr"
  spec.version       = TypedAttr::VERSION
  spec.authors       = ["Kurt Stephens"]
  spec.email         = ["ks.github@kurtstephens.com"]
  spec.description   = %q{Typed Attributes and Composite Types for Functional Programming in Ruby}
  spec.summary       = %q{typed_attr name: String, ...}
  spec.homepage      = "https://github.com/kstephens/typed_attr"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 2.14"
  spec.add_development_dependency "simplecov", "~> 0.8"
  spec.add_development_dependency "pry", "~> 0.9"
  spec.add_development_dependency "guard-rspec", "~> 4.0"
end
