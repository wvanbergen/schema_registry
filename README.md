# SchemaRegistry

Ruby client for Confluent Inc.'s schema-registry. The schema-registry holds AVRO schemas for different
subjects, and can ensure backward and/or forward compatiblity between different schema versions.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'schema_registry'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install schema_registry

## Usage

TODO: Write usage instructions here


### TLS

The registry does support client TLS cerificates as a means of authenticating w/ the schema registry.  

You have two options of passing options to net/http.  You can pass in all the config as named parameters

##### Example

```ruby
    @client = SchemaRegistry::Client.new(
      'https://testschmreg.domain.com:8082',
      cert: OpenSSL::X509::Certificate.new(File.read('./client.crt')), 
      key: OpenSSL::PKey::RSA.new(File.read('./client.key')),
      ca_file: './ca.pem',
      verify_mode: OpenSSL::SSL::VERIFY_PEER
    )
```

The second option is to use a helper static method to avoid having to handle the encoding.

##### Helper Example

```ruby
    @client = SchemaRegistry::Client.new(
      "https://testschmreg.domain.com:8082",
      SchemaRegistry::Client.connection_options(
        client_certificate: './client.crt', 
        client_key: './client.key',
        ca_certificate: "./ca.pem",
        verify_mode: :verify_peer
      )
    )
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/schema_registry/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
