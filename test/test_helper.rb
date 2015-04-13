# encoding: UTF-8
require 'minitest/autorun'
require 'minitest/pride'

require 'pp'
require 'avro'
require 'schema_registry'

def schema_fixture(name, version = 1, suffix = nil)
  schema_dirname = File.expand_path("../fixtures/schemas", __FILE__)
  schema_filename = "#{name}-v#{version}"
  schema_filename += suffix ? "-#{suffix}.avsc" : ".avsc"
  File.read(File.join(schema_dirname, schema_filename))
end
