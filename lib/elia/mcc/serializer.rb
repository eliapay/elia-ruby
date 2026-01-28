# frozen_string_literal: true

module Elia
  module Mcc
    # Serializer for MCC codes and related objects
    #
    # Provides consistent JSON/Hash representations for API responses.
    class Serializer
      DEFAULT_CODE_OPTIONS = {
        include_all_descriptions: false,
        include_categories: true,
        include_range: true,
      }.freeze

      # Serializes a Code object
      #
      # @param code [Code] the code to serialize
      # @param options [Hash] serialization options
      # @option options [Boolean] :include_all_descriptions (false) include all source descriptions
      # @option options [Boolean] :include_categories (true) include category data
      # @option options [Boolean] :include_range (true) include range data
      # @return [Hash] the serialized code
      def self.serialize_code(code, options = {})
        options = DEFAULT_CODE_OPTIONS.merge(options)
        result = base_code_hash(code)
        result.merge!(all_descriptions_hash(code)) if options[:include_all_descriptions]
        result[:categories] = code.categories.map(&:id) if options[:include_categories]
        result[:range] = code.range&.name if options[:include_range]
        result
      end

      def self.base_code_hash(code)
        { mcc: code.mcc, description: code.description,
          stripe_code: code.stripe_code, irs_reportable: code.irs_reportable?, }
      end

      def self.all_descriptions_hash(code)
        { iso_description: code.iso_description, usda_description: code.usda_description,
          stripe_description: code.stripe_description, visa_description: code.visa_description,
          visa_clearing_name: code.visa_clearing_name, mastercard_description: code.mastercard_description,
          amex_description: code.amex_description, alipay_description: code.alipay_description,
          irs_description: code.irs_description, }
      end

      private_class_method :base_code_hash, :all_descriptions_hash

      # Serializes a Category object
      #
      # @param category [Category] the category to serialize
      # @param options [Hash] serialization options
      # @return [Hash] the serialized category
      def self.serialize_category(category, options = {})
        result = {
          id: category.id,
          name: category.name,
          description: category.description,
        }

        result[:codes] = category.codes if options[:include_codes]

        result
      end

      # Serializes a Range object
      #
      # @param range [Range] the range to serialize
      # @param options [Hash] serialization options
      # @return [Hash] the serialized range
      def self.serialize_range(range, _options = {})
        {
          start_code: range.start_code,
          end_code: range.end_code,
          name: range.name,
          description: range.description,
          reserved: range.reserved?,
        }
      end

      # Serializes a collection of codes
      #
      # @param codes [Array<Code>] the codes to serialize
      # @param options [Hash] serialization options
      # @return [Array<Hash>] the serialized codes
      def self.serialize_collection(codes, options = {})
        codes.map { |code| serialize_code(code, options) }
      end
    end
  end
end
