require 'net/http'
require 'json'
require 'openssl'

module SchemaRegistry
  class ResponseError < Error
    attr_reader :code

    def initialize(code, message)
      @code = code
      super("#{message} (error code #{code})")
    end
  end

  InvalidResponse = Class.new(SchemaRegistry::Error)
  ServerError = Class.new(SchemaRegistry::ResponseError)

  RESPONSE_ERROR_CODES = {
    40401 => (SubjectNotFound           = Class.new(SchemaRegistry::ResponseError)),
    40402 => (VersionNotFound           = Class.new(SchemaRegistry::ResponseError)),
    40403 => (SchemaNotFound            = Class.new(SchemaRegistry::ResponseError)),
    42201 => (InvalidAvroSchema         = Class.new(SchemaRegistry::ResponseError)),
    42202 => (InvalidVersion            = Class.new(SchemaRegistry::ResponseError)),
    42203 => (InvalidCompatibilityLevel = Class.new(SchemaRegistry::ResponseError)),
    409   => (IncompatibleAvroSchema    = Class.new(SchemaRegistry::ResponseError)),
    403   => (UnauthorizedRequest       = Class.new(SchemaRegistry::ResponseError)),
  }

  class Client

    attr_reader :endpoint, :username, :password, :http_options

    def initialize(endpoint, username = nil, password = nil, flavour = "confluent", **http_options)
      @endpoint = URI(endpoint)
      @username, @password, @flavour = username, password, flavour
      @http_options = http_options
      if !["confluent", "apicurio"].include? flavour
        raise ArgumentError, "flavour must be one of 'confluent' or 'apicurio'"
      end
    end

    def schema(id)
      if @flavour == "confluent"
        request(:get, "/schemas/ids/#{id}")['schema']
      elsif @flavour == "apicurio"
        resp = request(:get, "/api/ids/#{id}")
        return resp
      end
    end

    def subjects
      data = request(:get, "/subjects")
      data.map { |subject| SchemaRegistry::Subject.new(self, subject) }
    end

    def subject(name)
      SchemaRegistry::Subject.new(self, name)
    end

    def default_compatibility_level
      request(:get, "/config")["compatibilityLevel"]
    end

    def default_compatibility_level=(level)
      request(:put, "/config", compatibility: level)
    end

    # Build options hash for net/http based on params provided. Primary for selectivly adding TLS config options for MTLS
    def self.connection_options(**config)
      options = {}

      unless config[:verify_mode].nil?
        options[:verify_mode] = OpenSSL::SSL.const_get(config[:verify_mode].upcase)
      end

      unless config[:ca_certificate].nil?
        if File.exist?(config[:ca_certificate])
          options[:ca_file] = config[:ca_certificate]
        else
          raise ArgumentError, "ca file not found [#{config[:ca_certificate]}]"
        end
      end

      unless config[:client_key].nil?
        if File.exist?(config[:client_key])
          options[:key] = OpenSSL::PKey::RSA.new(File.read(config[:client_key]))
        else
          raise ArgumentError, "client key file not found [#{config[:client_key]}]"
        end
      end

      unless config[:client_certificate].nil?
        if File.exist?(config[:client_certificate])
          options[:cert] = OpenSSL::X509::Certificate.new(File.read(config[:client_certificate]))
        else
          raise ArgumentError, "client cert file not found [#{config[:client_certificate]}]"
        end
      end
      options
    end

    def request(method, path, body = nil)

      # build config for http client
      default_options = {
        use_ssl: endpoint.scheme == 'https'
      }.merge!(@http_options)

      Net::HTTP.start(endpoint.host, endpoint.port, default_options) do |http|
        request_class = case method
          when :get;    Net::HTTP::Get
          when :post;   Net::HTTP::Post
          when :put;    Net::HTTP::Put
          when :delete; Net::HTTP::Delete
          else raise ArgumentError, "Unsupported request method"
        end

        request = request_class.new(@endpoint.path + path)
        request.basic_auth(username, password) if username && password
        if @flavour == "confluent"
          request['Accept'] = "application/vnd.schemaregistry.v1+json"
        elsif @flavour == "apicurio"
          request['Accept'] = "application/json"
        end
        if body
          request['Content-Type'] = "application/json"
          request.body = JSON.dump(body)
        end
        case response = http.request(request)
        when Net::HTTPOK
          begin
            JSON.parse(response.body)
          rescue JSON::ParserError => e
            raise SchemaRegistry::InvalidResponse, "Invalid JSON in response: #{e.message}"
          end
        when Net::HTTPSuccess
          begin
            JSON.parse(response.body)
          rescue JSON::ParserError => e
            raise SchemaRegistry::InvalidResponse, "Invalid JSON in response: #{e.message}"
          end
        when Net::HTTPInternalServerError
          raise SchemaRegistry::ServerError, "Schema registy responded with a server error: #{response.code.to_i}"

        when Net::HTTPForbidden
          message = username.nil? ? "Unauthorized" : "User `#{username}` failed to authenticate"
          raise SchemaRegistry::UnauthorizedRequest.new(response.code.to_i, message)

        else
          response_data = begin
            JSON.parse(response.body)
          rescue JSON::ParserError => e
            raise SchemaRegistry::InvalidResponse, "Invalid JSON in response: #{e.message}"
          end
        
          error_class = RESPONSE_ERROR_CODES[response_data['error_code']] || SchemaRegistry::ResponseError
          raise error_class.new(response_data['error_code'], response_data['message'])
        end
      end
    end
  end
end
