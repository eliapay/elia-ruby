# frozen_string_literal: true

module Elia
  module Mcc
    # Represents a risk category for MCC codes
    #
    # Categories help organize MCC codes by risk level, industry type,
    # or other business classification criteria for payment controls.
    class Category
      # @return [Symbol] unique identifier for this category
      attr_reader :id

      # @return [String] human-readable name
      attr_reader :name

      # @return [String] detailed description
      attr_reader :description

      # @return [Array<String>] array of codes and ranges (e.g., "7995" or "3000-3350")
      attr_reader :codes

      # Creates a new Category instance
      #
      # @param attributes [Hash] the category attributes
      # @option attributes [String, Symbol] :id unique identifier
      # @option attributes [String] :name human-readable name
      # @option attributes [String] :description detailed description
      # @option attributes [Array<String>] :codes array of codes and ranges
      def initialize(attributes = {})
        attributes = attributes.transform_keys(&:to_sym)

        @id = attributes[:id].to_sym
        @name = attributes[:name].to_s
        @description = attributes[:description].to_s
        @codes = Array(attributes[:codes]).map(&:to_s)
      end

      # Returns whether the given MCC code is in this category
      # Supports individual codes ("7995") and ranges ("3000-3350")
      #
      # @param mcc [String, Integer, Code] the code to check
      # @return [Boolean] true if the code is in this category
      def include?(mcc)
        code = mcc.respond_to?(:mcc) ? mcc.mcc : mcc
        normalized = code.to_s.strip.rjust(4, "0")

        codes.any? do |entry|
          if entry.include?("-")
            # Range entry like "3000-3350"
            start_code, end_code = entry.split("-").map { |c| c.strip.rjust(4, "0") }
            normalized.between?(start_code, end_code)
          else
            # Individual code like "7995"
            entry.strip.rjust(4, "0") == normalized
          end
        end
      end

      alias cover? include?

      # Returns whether this category equals another
      #
      # @param other [Category] the category to compare
      # @return [Boolean] true if the categories are equal
      def ==(other)
        return false unless other.is_a?(self.class)

        id == other.id
      end

      alias eql? ==

      # Returns a hash code for this instance
      #
      # @return [Integer] the hash code
      def hash
        id.hash
      end

      # Returns a human-readable representation
      #
      # @return [String] the inspection string
      def inspect
        "#<#{self.class.name} id=#{id.inspect} name=#{name.inspect} codes_count=#{codes.size}>"
      end

      # Returns the category as a string
      #
      # @return [String] the category name
      def to_s
        name
      end

      # Returns a hash representation
      #
      # @return [Hash] the category as a hash
      def to_h
        {
          id: id,
          name: name,
          description: description,
          codes: codes,
        }
      end
    end
  end
end
