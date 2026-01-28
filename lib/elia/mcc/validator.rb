# frozen_string_literal: true

module Elia
  module Mcc
    # Standalone validator for MCC codes
    #
    # Can be used independently of ActiveModel for basic validation.
    #
    # @example Basic usage
    #   validator = Elia::Mcc::Validator.new
    #   validator.valid?("5411")  # => true
    #   validator.valid?("XXXX")  # => false
    #
    # @example With category restrictions
    #   validator = Elia::Mcc::Validator.new(deny_categories: [:gambling, :adult])
    #   validator.valid?("7995")  # => false (gambling)
    class Validator
      # Default error messages
      MESSAGES = {
        invalid_format: "must be a valid 4-digit MCC code",
        not_found: "is not a recognized MCC code",
        denied_category: "is in a denied category",
      }.freeze

      # @return [Hash] validation options
      attr_reader :options

      # Creates a new Validator instance
      #
      # @param options [Hash] validation options
      # @option options [Boolean] :strict (true) require code to exist in registry
      # @option options [Array<Symbol>] :deny_categories categories to reject
      # @option options [Array<Symbol>] :allow_categories only allow these categories
      def initialize(options = {})
        @options = {
          strict: true,
          deny_categories: [],
          allow_categories: nil,
        }.merge(options)
      end

      # Validates the given value
      #
      # @param value [String, Integer, nil] the value to validate
      # @return [Array<String>] error messages (empty if valid)
      def validate(value)
        errors = []

        return errors if value.nil?

        # Check format
        unless valid_format?(value)
          errors << MESSAGES[:invalid_format]
          return errors
        end

        # Check if code exists (strict mode)
        if options[:strict]
          code = Elia::Mcc.find(value)
          if code.nil?
            errors << MESSAGES[:not_found]
            return errors
          end

          # Check category restrictions
          if options[:deny_categories].any?
            denied = options[:deny_categories].any? { |cat| code.in_category?(cat) }
            errors << MESSAGES[:denied_category] if denied
          end

          if options[:allow_categories]
            allowed = options[:allow_categories].any? { |cat| code.in_category?(cat) }
            errors << MESSAGES[:denied_category] unless allowed
          end
        end

        errors
      end

      # Returns whether the value is valid
      #
      # @param value [String, Integer, nil] the value to validate
      # @return [Boolean] true if valid
      def valid?(value)
        validate(value).empty?
      end

      private

      # Checks if the value has a valid MCC format
      #
      # @param value [String, Integer, nil] the value to check
      # @return [Boolean] true if the format is valid
      def valid_format?(value)
        return false if value.nil?

        normalized = value.to_s.strip
        normalized.match?(/\A\d{1,4}\z/)
      end
    end
  end
end
