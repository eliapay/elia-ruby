# frozen_string_literal: true

RSpec.describe Elia::Mcc do
  describe "VERSION" do
    it "has a version number" do
      expect(Elia::Mcc::VERSION).to eq("0.1.0")
    end
  end

  describe ".configuration" do
    it "returns a Configuration instance" do
      expect(described_class.configuration).to be_a(Elia::Mcc::Configuration)
    end

    it "returns the same instance on subsequent calls" do
      expect(described_class.configuration).to be(described_class.configuration)
    end
  end

  describe ".configure" do
    it "yields the configuration object" do
      expect { |b| described_class.configure(&b) }.to yield_with_args(Elia::Mcc::Configuration)
    end

    it "allows setting configuration options" do
      described_class.configure do |config|
        config.cache_enabled = false
      end

      expect(described_class.configuration.cache_enabled).to be(false)
    end
  end

  describe ".reset!" do
    it "creates a new configuration instance" do
      old_config = described_class.configuration
      described_class.reset!

      expect(described_class.configuration).not_to be(old_config)
    end
  end

  describe ".reset_configuration!" do
    it "is an alias for reset!" do
      old_config = described_class.configuration
      described_class.reset_configuration!

      expect(described_class.configuration).not_to be(old_config)
    end
  end

  describe ".find" do
    it "finds an MCC code by its value" do
      code = described_class.find("5411")
      expect(code).to be_a(Elia::Mcc::Code)
      expect(code.mcc).to eq("5411")
    end

    it "returns nil for non-existent code" do
      expect(described_class.find("0000")).to be_nil
    end
  end

  describe ".find!" do
    it "finds an MCC code by its value" do
      code = described_class.find!("5411")
      expect(code).to be_a(Elia::Mcc::Code)
      expect(code.mcc).to eq("5411")
    end

    it "raises NotFound for non-existent code" do
      expect { described_class.find!("0000") }.to raise_error(Elia::Mcc::NotFound)
    end
  end

  describe ".[]" do
    it "is an alias for find" do
      code = described_class["5411"]
      expect(code).to be_a(Elia::Mcc::Code)
      expect(code.mcc).to eq("5411")
    end
  end

  describe ".all" do
    it "returns all MCC codes" do
      codes = described_class.all
      expect(codes).to be_an(Array)
      expect(codes).not_to be_empty
      expect(codes.first).to be_a(Elia::Mcc::Code)
    end
  end

  describe ".search" do
    it "finds codes matching the query" do
      results = described_class.search("grocery")
      expect(results).to be_an(Array)
      expect(results).not_to be_empty
      expect(results.first).to be_a(Elia::Mcc::Code)
    end

    it "is case-insensitive" do
      results_lower = described_class.search("grocery")
      results_upper = described_class.search("GROCERY")
      expect(results_lower.map(&:mcc)).to eq(results_upper.map(&:mcc))
    end
  end

  describe ".ranges" do
    it "returns all ISO 18245 ranges" do
      ranges = described_class.ranges
      expect(ranges).to be_an(Array)
      expect(ranges).not_to be_empty
      expect(ranges.first).to be_a(Elia::Mcc::Range)
    end
  end

  describe ".categories" do
    it "returns all risk categories" do
      categories = described_class.categories
      expect(categories).to be_an(Array)
      expect(categories).not_to be_empty
      expect(categories.first).to be_a(Elia::Mcc::Category)
    end
  end

  describe ".in_category" do
    it "returns codes in the specified category" do
      codes = described_class.in_category(:gambling)
      expect(codes).to be_an(Array)
      expect(codes).not_to be_empty
      expect(codes.map(&:mcc)).to include("7995")
    end
  end

  describe ".valid?" do
    it "returns true for existing codes" do
      expect(described_class.valid?("5411")).to be(true)
    end

    it "returns false for non-existing codes" do
      expect(described_class.valid?("0000")).to be(false)
    end
  end
end
