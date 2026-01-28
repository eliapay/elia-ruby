# frozen_string_literal: true

module Elia
  # MCC (Merchant Category Code) module provides tools for working with
  # payment industry merchant category codes, including validation,
  # categorization, and risk assessment.
  module Mcc
    class << self
      # Returns the configuration object for the Mcc module
      #
      # @return [Configuration] the configuration instance
      def configuration
        @configuration ||= Configuration.new
      end

      # Yields the configuration object for block-based configuration
      #
      # @yield [Configuration] the configuration instance
      # @return [Configuration] the configuration instance
      def configure
        yield(configuration) if block_given?
        configuration
      end

      # Resets the configuration to defaults and clears the collection cache
      #
      # @return [Configuration] a new configuration instance
      def reset!
        @configuration = Configuration.new
        @collection = nil
        @configuration
      end

      alias reset_configuration! reset!

      # Delegate query methods to Collection
      delegate :all, :find, :find!, :[], :where, :in_range, :search,
               :in_category, :valid?, :count, :size, :reload!,
               to: :collection

      # Returns all ISO 18245 ranges
      #
      # @return [Array<Range>] all ranges
      def ranges
        collection.all_ranges
      end

      # Returns all risk categories
      #
      # @return [Array<Category>] all categories
      def categories
        collection.all_categories
      end

      private

      # Returns the collection instance, creating it if necessary
      #
      # @return [Collection] the collection instance
      def collection
        @collection ||= Collection.new
      end
    end
  end
end
