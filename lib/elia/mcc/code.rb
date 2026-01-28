# frozen_string_literal: true

module Elia
  module Mcc
    # Represents a single Merchant Category Code (MCC)
    #
    # MCC codes are 4-digit numbers used to classify businesses
    # by the type of goods or services they provide.
    class Code
      # @return [String] the 4-digit MCC code
      attr_reader :mcc

      # @return [String, nil] Official ISO 18245 description
      attr_reader :iso_description

      # @return [String, nil] USDA description
      attr_reader :usda_description

      # @return [String, nil] Stripe API description
      attr_reader :stripe_description

      # @return [String, nil] Stripe's snake_case identifier
      attr_reader :stripe_code

      # @return [String, nil] Visa description
      attr_reader :visa_description

      # @return [String, nil] Visa's abbreviated clearing name
      attr_reader :visa_clearing_name

      # @return [String, nil] Mastercard description
      attr_reader :mastercard_description

      # @return [String, nil] American Express description
      attr_reader :amex_description

      # @return [String, nil] Alipay description
      attr_reader :alipay_description

      # @return [String, nil] IRS description for tax reporting
      attr_reader :irs_description

      # @return [Boolean, nil] Whether transactions are reportable under IRS 6050W
      attr_reader :irs_reportable

      # Description source mapping
      DESCRIPTION_FIELDS = {
        iso: :iso_description,
        usda: :usda_description,
        stripe: :stripe_description,
        visa: :visa_description,
        mastercard: :mastercard_description,
        amex: :amex_description,
        alipay: :alipay_description,
        irs: :irs_description,
      }.freeze

      # Creates a new Code instance
      #
      # @param attributes [Hash] the code attributes
      # @option attributes [String, Integer] :mcc the 4-digit MCC code
      # @option attributes [String] :iso_description Official ISO 18245 description
      # @option attributes [String] :usda_description USDA description
      # @option attributes [String] :stripe_description Stripe API description
      # @option attributes [String] :stripe_code Stripe's snake_case identifier
      # @option attributes [String] :visa_description Visa description
      # @option attributes [String] :visa_clearing_name Visa's clearing name
      # @option attributes [String] :mastercard_description Mastercard description
      # @option attributes [String] :amex_description American Express description
      # @option attributes [String] :alipay_description Alipay description
      # @option attributes [String] :irs_description IRS description
      # @option attributes [Boolean] :irs_reportable Whether IRS reportable
      # @raise [InvalidCode] if the code format is invalid
      def initialize(attributes = {})
        attributes = attributes.transform_keys(&:to_sym)

        @mcc = normalize_code(attributes[:mcc])
        @iso_description = attributes[:iso_description]&.to_s.presence
        @usda_description = attributes[:usda_description]&.to_s.presence
        @stripe_description = attributes[:stripe_description]&.to_s.presence
        @stripe_code = attributes[:stripe_code]&.to_s.presence
        @visa_description = attributes[:visa_description]&.to_s.presence
        @visa_clearing_name = attributes[:visa_clearing_name]&.to_s.presence
        @mastercard_description = attributes[:mastercard_description]&.to_s.presence
        @amex_description = attributes[:amex_description]&.to_s.presence
        @alipay_description = attributes[:alipay_description]&.to_s.presence
        @irs_description = attributes[:irs_description]&.to_s.presence
        @irs_reportable = attributes[:irs_reportable]
      end

      # Returns whether this code is IRS reportable
      #
      # @return [Boolean] true if the code is IRS reportable
      def irs_reportable?
        @irs_reportable == true
      end

      # Returns the description based on the configured default source
      # Falls back through sources if the default is blank
      #
      # @param source [Symbol, nil] override the default source
      # @return [String, nil] the description
      def description(source: nil)
        source ||= Elia::Mcc.configuration.default_description_source

        # Try the requested source first
        field = DESCRIPTION_FIELDS[source]
        result = send(field) if field

        return result if result.present?

        # Fall back through other sources in order
        DESCRIPTION_FIELDS.each_value do |field_name|
          result = send(field_name)
          return result if result.present?
        end

        nil
      end

      # Returns the ISO 18245 range this code belongs to
      #
      # @return [Range, nil] the range containing this code
      def range
        Elia::Mcc.ranges.find { |r| r.include?(mcc) }
      end

      # Returns all categories this code belongs to
      #
      # @return [Array<Category>] the categories containing this code
      def categories
        Elia::Mcc.categories.select { |c| c.include?(mcc) }
      end

      # Returns whether this code is in the given category
      #
      # @param category [Category, Symbol, String] the category to check
      # @return [Boolean] true if in the category
      def in_category?(category)
        category_id = case category
                      when Category then category.id
                      when Symbol then category
                      else category.to_s.to_sym
                      end

        Elia::Mcc.in_category(category_id).any? { |c| c.mcc == mcc }
      end

      # Returns whether this code matches the given value
      #
      # @param other [String, Integer, Code] the value to compare
      # @return [Boolean] true if the codes match
      def ==(other)
        case other
        when Code
          mcc == other.mcc
        when String, Integer
          mcc == normalize_code(other)
        else
          false
        end
      end

      alias eql? ==

      # Returns a hash code for this instance
      #
      # @return [Integer] the hash code
      def hash
        mcc.hash
      end

      # Returns the code as an integer
      #
      # @return [Integer] the numeric value of the code
      def to_i
        mcc.to_i
      end

      # Returns the code as a string
      #
      # @return [String] the 4-digit code string
      def to_s
        mcc
      end

      # Returns a human-readable representation
      #
      # @return [String] the inspection string
      def inspect
        "#<#{self.class.name} mcc=#{mcc.inspect} description=#{description.inspect}>"
      end

      # Returns a hash representation of all attributes
      #
      # @return [Hash] all attributes as a hash
      def to_h
        {
          mcc: mcc,
          iso_description: iso_description,
          usda_description: usda_description,
          stripe_description: stripe_description,
          stripe_code: stripe_code,
          visa_description: visa_description,
          visa_clearing_name: visa_clearing_name,
          mastercard_description: mastercard_description,
          amex_description: amex_description,
          alipay_description: alipay_description,
          irs_description: irs_description,
          irs_reportable: irs_reportable,
        }
      end

      # Returns a JSON-compatible hash representation
      #
      # @param options [Hash] JSON options (unused, for compatibility)
      # @return [Hash] JSON-compatible hash
      def as_json(_options = {})
        to_h.merge(
          description: description,
          categories: categories.map(&:id),
          range: range&.name
        )
      end

      private

      # Normalizes a code value to a 4-digit string
      #
      # @param value [String, Integer] the value to normalize
      # @return [String] the normalized 4-digit string
      # @raise [InvalidCode] if the value cannot be normalized
      def normalize_code(value)
        normalized = value.to_s.strip.rjust(4, "0")

        raise InvalidCode, value unless normalized.match?(/\A\d{4}\z/)

        normalized
      end
    end
  end
end
