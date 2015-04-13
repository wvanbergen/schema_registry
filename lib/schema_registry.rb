module SchemaRegistry

  module Compatibility
    FORWARD  = "FORWARD".freeze
    BACKWARD = "BACKWARD".freeze
    FULL     = "FULL".freeze
    NONE     = "NONE".freeze

    LEVELS = [NONE, FORWARD, BACKWARD, FULL].freeze
  end

  class Error < ::StandardError
  end
end

require 'schema_registry/client'
require 'schema_registry/subject'
require 'schema_registry/version'
