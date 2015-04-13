require 'test_helper'

class SchemaRegistryTest < Minitest::Test

  def setup
    raise "The SCHEMA_REGISTRY_URI environment variable must be set" if ENV['SCHEMA_REGISTRY_URI'].nil?
    @client = SchemaRegistry::Client.new(ENV['SCHEMA_REGISTRY_URI'])
  end

  def test_global_compatibility_level
    old_level = @client.default_compatibility_level
    assert_equal SchemaRegistry::Compatibility::BACKWARD, old_level

    @client.default_compatibility_level = SchemaRegistry::Compatibility::FULL

    current_level = @client.default_compatibility_level
    assert_equal current_level, SchemaRegistry::Compatibility::FULL
  ensure
    @client.default_compatibility_level = old_level
  end

  def test_register_schema_for_subject
    schema = schema_fixture('test', 1)

    subject = @client.subject('test.schema_registry')
    schema_id = subject.update_schema(schema)
    assert schema_id > 0

    assert_equal ['test.schema_registry'], @client.subjects.map(&:name)

    registered_schema = @client.schema(schema_id)
    schema_info = subject.verify_schema(schema)
    assert_equal schema_id, schema_info['id']

    assert_equal Avro::Schema.parse(schema), Avro::Schema.parse(registered_schema)

    parsed_schema = JSON.parse(registered_schema)
    assert_equal 'Only used for testing', parsed_schema['doc']
    assert_equal 'present', parsed_schema['metafata_field']
  end
end
