# frozen_string_literal: true

require "yaml"
require "active_support/core_ext/enumerable"

module Elia
  module Mcc
    # Provides data loading, caching, and query functionality for MCC codes
    #
    # The Collection class is the main workhorse that loads YAML data files,
    # caches the results, and provides query methods for searching and filtering.
    class Collection
      # @return [Array<Code>] all loaded MCC codes
      attr_reader :codes

      # @return [Array<Range>] all loaded ISO 18245 ranges
      attr_reader :ranges

      # @return [Array<Category>] all loaded risk categories
      attr_reader :categories

      def initialize
        @codes = []
        @ranges = []
        @categories = []
        @loaded = false
        @mutex = Mutex.new
      end

      # Returns all MCC codes, loading them if necessary
      #
      # @return [Array<Code>] all registered codes
      def all
        ensure_loaded!
        @codes
      end

      # Finds an MCC code by its numeric value
      #
      # @param code [String, Integer] the code to find
      # @return [Code, nil] the matching code or nil
      def find(code)
        ensure_loaded!
        normalized = normalize_code(code)
        @codes_index ||= @codes.index_by(&:mcc)
        @codes_index[normalized]
      end

      # Finds an MCC code or raises an error
      #
      # @param code [String, Integer] the code to find
      # @return [Code] the matching code
      # @raise [NotFound] if the code is not found
      def find!(code)
        find(code) || raise(NotFound, code)
      end

      # Bracket accessor for finding codes
      #
      # @param code [String, Integer] the code to find
      # @return [Code, nil] the matching code or nil
      def [](code)
        find(code)
      end

      # Filters codes by attribute conditions
      #
      # @param conditions [Hash] attribute conditions to match
      # @return [Array<Code>] matching codes
      def where(conditions = {})
        ensure_loaded!
        result = @codes

        conditions.each do |attr, value|
          result = result.select do |code|
            code_value = code.respond_to?(attr) ? code.public_send(attr) : nil
            case value
            when Regexp
              code_value.to_s.match?(value)
            when Array
              value.include?(code_value)
            else
              code_value == value
            end
          end
        end

        result
      end

      # Returns codes within the given ISO 18245 range
      #
      # @param range_name [String, Symbol] the name of the range
      # @return [Array<Code>] codes in the range
      def in_range(range_name)
        ensure_loaded!
        range = @ranges.find { |r| r.name.downcase == range_name.to_s.downcase }
        return [] unless range

        @codes.select { |code| range.include?(code.mcc) }
      end

      # Searches for codes matching the given query across all description fields
      # Case-insensitive fuzzy matching
      #
      # @param query [String] the search query
      # @return [Array<Code>] matching codes
      def search(query)
        ensure_loaded!
        return @codes if query.to_s.strip.empty?

        query_downcase = query.to_s.downcase

        @codes.select do |code|
          # Search across all description fields and code
          searchable_text = [
            code.mcc,
            code.iso_description,
            code.usda_description,
            code.stripe_description,
            code.stripe_code,
            code.visa_description,
            code.visa_clearing_name,
            code.mastercard_description,
            code.amex_description,
            code.alipay_description,
            code.irs_description,
          ].compact.join(" ")

          searchable_text.downcase.include?(query_downcase)
        end
      end

      # Returns codes in the given category
      #
      # @param category_id [Symbol, String] the category identifier
      # @return [Array<Code>] codes in the category
      def in_category(category_id)
        ensure_loaded!
        category = @categories.find { |c| c.id == category_id.to_sym }
        return [] unless category

        @codes.select { |code| category.include?(code.mcc) }
      end

      # Returns all loaded ranges
      #
      # @return [Array<Range>] all ranges
      def all_ranges
        ensure_loaded!
        @ranges
      end

      # Returns all loaded categories
      #
      # @return [Array<Category>] all categories
      def all_categories
        ensure_loaded!
        @categories
      end

      # Returns whether the given code is valid (exists in the collection)
      #
      # @param code [String, Integer] the code to check
      # @return [Boolean] true if the code exists
      def valid?(code)
        !find(code).nil?
      end

      alias exists? valid?

      # Returns the count of loaded codes
      #
      # @return [Integer] the number of codes
      def count
        all.size
      end

      alias size count

      # Reloads all data from the YAML files
      #
      # @return [self]
      def reload!
        @mutex.synchronize do
          @loaded = false
          @codes = []
          @ranges = []
          @categories = []
          @codes_index = nil
        end
        ensure_loaded!
        self
      end

      private

      # Ensures data is loaded, loading it if necessary
      def ensure_loaded!
        return if @loaded && Elia::Mcc.configuration.cache_enabled

        @mutex.synchronize do
          return if @loaded && Elia::Mcc.configuration.cache_enabled

          load_data!
          @loaded = true
        end
      end

      # Loads all data from YAML files
      def load_data!
        data_path = Elia::Mcc.configuration.data_path

        load_codes!(File.join(data_path, "mcc_codes.yml"))
        load_ranges!(File.join(data_path, "ranges.yml"))
        load_categories!(File.join(data_path, "risk_categories.yml"))

        @codes_index = nil # Reset index after loading
      end

      # Loads MCC codes from the YAML file
      #
      # @param file_path [String] path to the YAML file
      def load_codes!(file_path)
        data = load_yaml(file_path)
        @codes = data.map { |attrs| Code.new(attrs) }
      rescue StandardError => e
        raise DataLoadError.new(file_path, e)
      end

      # Loads ISO 18245 ranges from the YAML file
      #
      # @param file_path [String] path to the YAML file
      def load_ranges!(file_path)
        data = load_yaml(file_path)
        @ranges = data.map { |attrs| Range.new(attrs) }
      rescue StandardError => e
        raise DataLoadError.new(file_path, e)
      end

      # Loads risk categories from the YAML file
      #
      # @param file_path [String] path to the YAML file
      def load_categories!(file_path)
        data = load_yaml(file_path)

        @categories = data.map do |id, attrs|
          Category.new(
            id: id,
            name: attrs["name"],
            description: attrs["description"],
            codes: attrs["codes"]
          )
        end
      rescue StandardError => e
        raise DataLoadError.new(file_path, e)
      end

      # Loads and parses a YAML file
      #
      # @param file_path [String] path to the YAML file
      # @return [Hash, Array] the parsed YAML data
      def load_yaml(file_path)
        YAML.load_file(file_path, permitted_classes: [Symbol])
      end

      # Normalizes a code value to a 4-digit string
      #
      # @param value [String, Integer] the value to normalize
      # @return [String] the normalized 4-digit string
      def normalize_code(value)
        value.to_s.strip.rjust(4, "0")
      end
    end
  end
end
