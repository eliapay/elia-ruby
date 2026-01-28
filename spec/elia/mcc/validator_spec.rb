# frozen_string_literal: true

RSpec.describe Elia::Mcc::Validator do
  describe "#initialize" do
    context "with default options" do
      let(:validator) { described_class.new }

      it "sets strict to true by default" do
        expect(validator.options[:strict]).to be(true)
      end

      it "sets deny_categories to empty array" do
        expect(validator.options[:deny_categories]).to eq([])
      end

      it "sets allow_categories to nil" do
        expect(validator.options[:allow_categories]).to be_nil
      end
    end

    context "with custom options" do
      let(:validator) do
        described_class.new(
          strict: false,
          deny_categories: [:gambling],
          allow_categories: [:healthcare]
        )
      end

      it "sets strict option" do
        expect(validator.options[:strict]).to be(false)
      end

      it "sets deny_categories option" do
        expect(validator.options[:deny_categories]).to eq([:gambling])
      end

      it "sets allow_categories option" do
        expect(validator.options[:allow_categories]).to eq([:healthcare])
      end
    end
  end

  describe "#validate" do
    context "with valid format codes" do
      let(:validator) { described_class.new(strict: false) }

      it "returns empty array for valid 4-digit codes" do
        expect(validator.validate("5411")).to eq([])
        expect(validator.validate("0742")).to eq([])
      end

      it "returns empty array for valid 1-4 digit codes" do
        expect(validator.validate("1")).to eq([])
        expect(validator.validate("12")).to eq([])
        expect(validator.validate("123")).to eq([])
        expect(validator.validate("1234")).to eq([])
      end

      it "returns empty array for integer codes" do
        expect(validator.validate(5411)).to eq([])
        expect(validator.validate(742)).to eq([])
      end

      it "returns empty array for nil values" do
        expect(validator.validate(nil)).to eq([])
      end
    end

    context "with invalid format codes" do
      let(:validator) { described_class.new(strict: false) }

      it "returns error for non-numeric codes" do
        errors = validator.validate("ABCD")

        expect(errors).to include(Elia::Mcc::Validator::MESSAGES[:invalid_format])
      end

      it "returns error for codes with special characters" do
        errors = validator.validate("54-11")

        expect(errors).to include(Elia::Mcc::Validator::MESSAGES[:invalid_format])
      end

      it "returns error for codes longer than 4 digits" do
        errors = validator.validate("12345")

        expect(errors).to include(Elia::Mcc::Validator::MESSAGES[:invalid_format])
      end

      it "returns error for empty string" do
        errors = validator.validate("")

        expect(errors).to include(Elia::Mcc::Validator::MESSAGES[:invalid_format])
      end
    end

    context "with strict mode enabled" do
      let(:validator) { described_class.new(strict: true) }

      it "returns empty array for existing codes" do
        expect(validator.validate("5411")).to eq([])
        expect(validator.validate("0742")).to eq([])
      end

      it "returns not_found error for non-existing codes" do
        errors = validator.validate("0001")

        expect(errors).to include(Elia::Mcc::Validator::MESSAGES[:not_found])
      end
    end

    context "with strict mode disabled" do
      let(:validator) { described_class.new(strict: false) }

      it "does not check code existence" do
        errors = validator.validate("0001")

        expect(errors).to eq([])
      end
    end

    context "with deny_categories option" do
      let(:validator) { described_class.new(strict: true, deny_categories: [:gambling]) }

      it "returns error for codes in denied categories" do
        errors = validator.validate("7995")

        expect(errors).to include(Elia::Mcc::Validator::MESSAGES[:denied_category])
      end

      it "returns empty array for codes not in denied categories" do
        errors = validator.validate("5411")

        expect(errors).to eq([])
      end

      it "works with multiple denied categories" do
        validator = described_class.new(
          strict: true,
          deny_categories: %i[gambling adult]
        )

        expect(validator.validate("7995")).to include(Elia::Mcc::Validator::MESSAGES[:denied_category])
        expect(validator.validate("7273")).to include(Elia::Mcc::Validator::MESSAGES[:denied_category])
        expect(validator.validate("5411")).to eq([])
      end
    end

    context "with allow_categories option" do
      let(:validator) { described_class.new(strict: true, allow_categories: [:healthcare]) }

      it "returns empty array for codes in allowed categories" do
        errors = validator.validate("8011") # Doctors

        expect(errors).to eq([])
      end

      it "returns error for codes not in allowed categories" do
        errors = validator.validate("5411") # Grocery stores

        expect(errors).to include(Elia::Mcc::Validator::MESSAGES[:denied_category])
      end

      it "works with multiple allowed categories" do
        validator = described_class.new(
          strict: true,
          allow_categories: %i[healthcare education]
        )

        expect(validator.validate("8011")).to eq([]) # Healthcare
        expect(validator.validate("8211")).to eq([]) # Education
        expect(validator.validate("5411")).to include(Elia::Mcc::Validator::MESSAGES[:denied_category])
      end
    end

    context "with both deny_categories and allow_categories" do
      let(:validator) do
        described_class.new(
          strict: true,
          deny_categories: [:gambling],
          allow_categories: [:healthcare]
        )
      end

      it "applies both restrictions" do
        # Healthcare code should be allowed
        expect(validator.validate("8011")).to eq([])

        # Non-healthcare code should be denied
        expect(validator.validate("5411")).to include(Elia::Mcc::Validator::MESSAGES[:denied_category])

        # Gambling code should also be denied (even if deny_categories checked first)
        expect(validator.validate("7995")).to include(Elia::Mcc::Validator::MESSAGES[:denied_category])
      end
    end

    context "with multiple validation rules" do
      let(:validator) { described_class.new(strict: true, deny_categories: [:gambling]) }

      it "returns format error first without checking other validations" do
        errors = validator.validate("XXXX")

        expect(errors.length).to eq(1)
        expect(errors.first).to eq(Elia::Mcc::Validator::MESSAGES[:invalid_format])
      end

      it "returns not_found error before category errors" do
        errors = validator.validate("0001")

        expect(errors.length).to eq(1)
        expect(errors.first).to eq(Elia::Mcc::Validator::MESSAGES[:not_found])
      end
    end
  end

  describe "#valid?" do
    let(:validator) { described_class.new }

    it "returns true when validate returns empty array" do
      expect(validator.valid?("5411")).to be(true)
    end

    it "returns false when validate returns errors" do
      expect(validator.valid?("XXXX")).to be(false)
    end

    it "returns true for nil values" do
      expect(validator.valid?(nil)).to be(true)
    end
  end

  describe "MESSAGES constant" do
    it "provides invalid_format message" do
      expect(described_class::MESSAGES[:invalid_format]).to eq("must be a valid 4-digit MCC code")
    end

    it "provides not_found message" do
      expect(described_class::MESSAGES[:not_found]).to eq("is not a recognized MCC code")
    end

    it "provides denied_category message" do
      expect(described_class::MESSAGES[:denied_category]).to eq("is in a denied category")
    end
  end

  describe "edge cases" do
    context "with whitespace in codes" do
      let(:validator) { described_class.new(strict: false) }

      it "handles leading/trailing whitespace" do
        expect(validator.validate("  5411  ")).to eq([])
      end
    end

    context "with symbols as category names" do
      let(:validator) { described_class.new(strict: true, deny_categories: [:gambling]) }

      it "handles symbol category names" do
        expect(validator.validate("7995")).to include(Elia::Mcc::Validator::MESSAGES[:denied_category])
      end
    end
  end
end
