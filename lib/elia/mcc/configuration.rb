# frozen_string_literal: true

module Elia
  module Mcc
    # Configuration class for the Mcc module
    #
    # Provides settings for data file paths, caching behavior,
    # description source preference, and other customization options.
    class Configuration
      # Valid description sources from the MCC data
      DESCRIPTION_SOURCES = %i[
        iso usda stripe visa mastercard amex alipay irs
      ].freeze

      # @return [Symbol] the default source for description lookups
      attr_accessor :default_description_source

      # @return [Boolean] whether to include reserved MCC ranges in queries
      attr_accessor :include_reserved_ranges

      # @return [Boolean] whether to enable caching of loaded data
      attr_accessor :cache_enabled

      # @return [String] path to the directory containing MCC data files
      attr_accessor :data_path

      # @return [Logger, nil] optional logger for debugging
      attr_accessor :logger

      def initialize
        @default_description_source = :iso
        @include_reserved_ranges = false
        @cache_enabled = true
        @data_path = default_data_path
        @logger = nil
      end

      # Returns the default path to the data directory
      #
      # @return [String] the default data path
      def default_data_path
        File.expand_path("data", __dir__)
      end

      # Validates the current configuration
      #
      # @raise [ConfigurationError] if the configuration is invalid
      # @return [true] if the configuration is valid
      def validate!
        raise ConfigurationError, "data_path cannot be blank" if data_path.to_s.strip.empty?

        unless DESCRIPTION_SOURCES.include?(default_description_source)
          raise ConfigurationError,
                "default_description_source must be one of: #{DESCRIPTION_SOURCES.join(", ")}"
        end

        true
      end

      # Resets the configuration to defaults
      #
      # @return [self]
      def reset!
        @default_description_source = :iso
        @include_reserved_ranges = false
        @cache_enabled = true
        @data_path = default_data_path
        @logger = nil
        self
      end

      # Returns a hash representation of the configuration
      #
      # @return [Hash] the configuration as a hash
      def to_h
        {
          default_description_source: default_description_source,
          include_reserved_ranges: include_reserved_ranges,
          cache_enabled: cache_enabled,
          data_path: data_path,
        }
      end
    end
  end
end
