# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'schema_registry/version'

Gem::Specification.new do |spec|
  spec.name          = "schema_registry"
  spec.version       = SchemaRegistry::VERSION
  spec.authors       = ["Willem van Bergen"]
  spec.email         = ["willem@railsdoctors.com"]
  spec.summary       = %q{Ruby client for Confluent Inc.'s schema-registry}
  spec.description   = %q{Ruby client for Confluent Inc.'s schema-registry. The schema-registry holds AVRO schemas for different subjects, and can ensure backward and/or forward compatiblity between different schema versions.}
  spec.homepage      = "http://confluent.io/docs/current/schema-registry/docs/index.html"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "avro", "~> 1.7"
end
