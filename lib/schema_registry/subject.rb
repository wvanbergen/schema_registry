module SchemaRegistry

  class Subject
    attr_reader :client, :name

    def initialize(client, name)
      @client, @name = client, name
    end

    def versions
      client.request(:get, "/subjects/#{name}/versions")
    end

    def version(version)
      client.request(:get, "/subjects/#{name}/versions/#{version}")
    end

    def verify_schema(schema_json)
      client.request(:post, "/subjects/#{name}", schema: schema_json)
    end

    def update_schema(schema_json)
      client.request(:post, "/subjects/#{name}/versions", schema: schema_json)["id"]
    end

    def compatibility_level
      response = client.request(:get, "/config/#{name}")
      response["compatibilityLevel"]
    end

    def compatibility_level=(level)
      response = client.request(:put, "/config/#{name}", compatibility: level)
    end

    def compatible?(schema, version = "latest")
      response = client.request(:post, "/compatibility/subjects/#{name}/versions/#{version}", schema: schema)
      response["is_compatible"]
    end
  end
end
