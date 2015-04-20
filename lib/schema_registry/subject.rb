module SchemaRegistry

  class SchemaRegistration
    attr_accessor :subject, :id, :version, :schema

    def initialize(subject, options = {})
      @subject = subject
      @id      = options['id']
      @version = options['version']
      @schema  = options['schema']
    end

    def pretty_json
      JSON.pretty_generate(JSON.parse(@schema))
    end
  end

  class Subject
    attr_reader :client, :name

    def initialize(client, name)
      @client, @name = client, name
    end

    def versions
      client.request(:get, "/subjects/#{name}/versions")
    end

    def version(version)
      SchemaRegistration.new(self, client.request(:get, "/subjects/#{name}/versions/#{version}"))
    end

    def verify_schema(schema_json)
      SchemaRegistration.new(self, client.request(:post, "/subjects/#{name}", schema: schema_json))
    end

    def schema_registered?(schema_json)
      verify_schema(schema_json)
      true
    rescue SubjectNotFound, SchemaNotFound
      false
    end

    def register_schema(schema_json)
      client.request(:post, "/subjects/#{name}/versions", schema: schema_json)['id']
    end

    def compatibility_level
      response = client.request(:get, "/config/#{name}")
      response["compatibilityLevel"]
    end

    def compatibility_level=(level)
      client.request(:put, "/config/#{name}", compatibility: level)
    end

    def compatible?(schema, version = "latest")
      response = client.request(:post, "/compatibility/subjects/#{name}/versions/#{version}", schema: schema)
      response["is_compatible"]
    end
  end
end
