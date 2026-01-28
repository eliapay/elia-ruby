# frozen_string_literal: true

module Elia
  module Mcc
    # Base error class for all MCC-related errors
    class Error < StandardError; end

    # Raised when an MCC code is not found in the registry
    class NotFound < Error
      def initialize(code)
        super("MCC code not found: #{code.inspect}")
      end
    end

    # Raised when an invalid MCC code format is provided
    class InvalidCode < Error
      def initialize(code)
        super("Invalid MCC code format: #{code.inspect}. Expected a 4-digit string or integer.")
      end
    end

    # Raised when an invalid range is specified
    class InvalidRange < Error
      def initialize(message = "Invalid MCC range specified")
        super
      end
    end

    # Raised when configuration is invalid
    class ConfigurationError < Error; end

    # Raised when data files cannot be loaded
    class DataLoadError < Error
      def initialize(file_path, original_error = nil)
        message = "Failed to load MCC data from: #{file_path}"
        message += " (#{original_error.message})" if original_error
        super(message)
      end
    end

    # Raised when a category is not found
    class CategoryNotFound < Error
      def initialize(category)
        super("Category not found: #{category.inspect}")
      end
    end
  end
end
