# frozen_string_literal: true

require "active_model"

# ActiveModel validator for MCC codes
#
# @example Basic usage
#   class Transaction < ApplicationRecord
#     validates :mcc_code, mcc: true
#   end
#
# @example With category restrictions
#   class Transaction < ApplicationRecord
#     validates :mcc_code, mcc: { deny_categories: [:gambling, :adult] }
#   end
#
# @example With custom message
#   class Transaction < ApplicationRecord
#     validates :mcc_code, mcc: {
#       deny_categories: [:gambling],
#       message: "category is blocked"
#     }
#   end
class MccValidator < ActiveModel::EachValidator
  # Validates an attribute on a record
  #
  # @param record [Object] the record being validated
  # @param attribute [Symbol] the attribute name
  # @param value [Object] the attribute value
  def validate_each(record, attribute, value)
    return if value.blank? && options[:allow_blank]

    validator = Elia::Mcc::Validator.new(validator_options)
    errors = validator.validate(value)

    errors.each do |message|
      record.errors.add(attribute, options[:message] || message)
    end
  end

  private

  def validator_options
    {
      strict: options.fetch(:strict, true),
      deny_categories: Array(options[:deny_categories]),
      allow_categories: options[:allow_categories],
    }
  end
end
