# frozen_string_literal: true

module Elia
  module Mcc
    # Represents an ISO 18245 MCC range
    #
    # Ranges define groups of related MCC codes by industry segment
    # according to the ISO 18245 standard.
    class Range
      # @return [String] the starting MCC code (inclusive)
      attr_reader :start_code

      # @return [String] the ending MCC code (inclusive)
      attr_reader :end_code

      # @return [String] the name of this range
      attr_reader :name

      # @return [String] description of this range
      attr_reader :description

      # @return [Boolean] whether this range is reserved
      attr_reader :reserved

      # Creates a new Range instance
      #
      # @param attributes [Hash] the range attributes
      # @option attributes [String, Integer] :start the starting MCC code
      # @option attributes [String, Integer] :end the ending MCC code
      # @option attributes [String] :name the name of the range
      # @option attributes [String] :description description of the range
      # @option attributes [Boolean] :reserved whether the range is reserved
      # @raise [InvalidRange] if the range is invalid
      def initialize(attributes = {})
        attributes = attributes.transform_keys(&:to_sym)

        @start_code = normalize_code(attributes[:start] || attributes[:start_code])
        @end_code = normalize_code(attributes[:end] || attributes[:end_code])
        @name = attributes[:name].to_s
        @description = attributes[:description].to_s
        @reserved = attributes[:reserved] == true

        validate!
      end

      # Returns whether the given code falls within this range
      #
      # @param mcc [String, Integer, Code] the code to check
      # @return [Boolean] true if the code is within the range
      def include?(mcc)
        code = mcc.respond_to?(:mcc) ? mcc.mcc : mcc
        normalized = normalize_code(code)
        normalized.between?(start_code, end_code)
      end

      alias cover? include?

      # Returns whether this range is reserved
      #
      # @return [Boolean] true if reserved
      def reserved?
        @reserved == true
      end

      # Returns the number of codes in this range
      #
      # @return [Integer] the count of codes
      def size
        end_code.to_i - start_code.to_i + 1
      end

      alias count size
      alias length size

      # Returns all codes in this range as an array of strings
      #
      # @return [Array<String>] all codes in the range
      def to_a
        (start_code.to_i..end_code.to_i).map { |n| n.to_s.rjust(4, "0") }
      end

      # Iterates over each code in the range
      #
      # @yield [String] each code in the range
      # @return [Enumerator] if no block given
      def each(&block)
        return to_enum(:each) unless block_given?

        to_a.each(&block)
      end

      # Returns whether this range equals another
      #
      # @param other [Range] the range to compare
      # @return [Boolean] true if the ranges are equal
      def ==(other)
        return false unless other.is_a?(self.class)

        start_code == other.start_code && end_code == other.end_code
      end

      alias eql? ==

      # Returns a hash code for this instance
      #
      # @return [Integer] the hash code
      def hash
        [start_code, end_code].hash
      end

      # Returns a human-readable representation
      #
      # @return [String] the inspection string
      def inspect
        "#<#{self.class.name} #{start_code}..#{end_code} name=#{name.inspect} reserved=#{reserved?}>"
      end

      # Returns the range as a string
      #
      # @return [String] the range representation
      def to_s
        "#{start_code}-#{end_code}"
      end

      # Returns a hash representation
      #
      # @return [Hash] the range as a hash
      def to_h
        {
          start_code: start_code,
          end_code: end_code,
          name: name,
          description: description,
          reserved: reserved,
        }
      end

      private

      # Validates that the range is valid
      #
      # @raise [InvalidRange] if the range is invalid
      def validate!
        return unless start_code.to_i > end_code.to_i

        raise InvalidRange, "Start code (#{start_code}) cannot be greater than end code (#{end_code})"
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
