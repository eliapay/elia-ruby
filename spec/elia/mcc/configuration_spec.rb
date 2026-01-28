# frozen_string_literal: true

RSpec.describe Elia::Mcc::Configuration do
  let(:config) { described_class.new }

  describe "#initialize" do
    it "sets default_description_source to :iso" do
      expect(config.default_description_source).to eq(:iso)
    end

    it "sets include_reserved_ranges to false" do
      expect(config.include_reserved_ranges).to be(false)
    end

    it "sets cache_enabled to true" do
      expect(config.cache_enabled).to be(true)
    end

    it "sets data_path to default" do
      expect(config.data_path).to eq(config.default_data_path)
    end

    it "sets logger to nil" do
      expect(config.logger).to be_nil
    end
  end

  describe "#default_description_source" do
    it "can be set to valid sources" do
      described_class::DESCRIPTION_SOURCES.each do |source|
        config.default_description_source = source
        expect(config.default_description_source).to eq(source)
      end
    end

    it "accepts symbol values" do
      config.default_description_source = :stripe
      expect(config.default_description_source).to eq(:stripe)
    end
  end

  describe "#include_reserved_ranges" do
    it "can be set to true" do
      config.include_reserved_ranges = true
      expect(config.include_reserved_ranges).to be(true)
    end

    it "can be set to false" do
      config.include_reserved_ranges = false
      expect(config.include_reserved_ranges).to be(false)
    end
  end

  describe "#cache_enabled" do
    it "can be set to true" do
      config.cache_enabled = true
      expect(config.cache_enabled).to be(true)
    end

    it "can be set to false" do
      config.cache_enabled = false
      expect(config.cache_enabled).to be(false)
    end
  end

  describe "#data_path" do
    it "can be set to a custom path" do
      config.data_path = "/custom/path"
      expect(config.data_path).to eq("/custom/path")
    end

    it "defaults to lib/elia/mcc/data" do
      expect(config.data_path).to include("lib/elia/mcc/data")
    end
  end

  describe "#logger" do
    it "can be set to a logger instance" do
      logger = Logger.new($stdout)
      config.logger = logger
      expect(config.logger).to eq(logger)
    end

    it "can be set to nil" do
      config.logger = nil
      expect(config.logger).to be_nil
    end
  end

  describe "#default_data_path" do
    it "returns the path to the data directory" do
      path = config.default_data_path

      expect(path).to be_a(String)
      expect(path).to include("data")
    end

    it "returns an absolute path" do
      path = config.default_data_path

      expect(path).to start_with("/")
    end
  end

  describe "#validate!" do
    context "with valid configuration" do
      it "returns true" do
        expect(config.validate!).to be(true)
      end
    end

    context "with blank data_path" do
      it "raises ConfigurationError for empty string" do
        config.data_path = ""

        expect { config.validate! }.to raise_error(Elia::Mcc::ConfigurationError, /data_path cannot be blank/)
      end

      it "raises ConfigurationError for whitespace-only string" do
        config.data_path = "   "

        expect { config.validate! }.to raise_error(Elia::Mcc::ConfigurationError, /data_path cannot be blank/)
      end
    end

    context "with invalid default_description_source" do
      it "raises ConfigurationError" do
        config.default_description_source = :invalid_source

        expect { config.validate! }.to raise_error(
          Elia::Mcc::ConfigurationError,
          /default_description_source must be one of/
        )
      end

      it "lists valid sources in error message" do
        config.default_description_source = :invalid_source

        expect { config.validate! }.to raise_error(
          Elia::Mcc::ConfigurationError,
          /iso.*usda.*stripe.*visa.*mastercard.*amex.*alipay.*irs/
        )
      end
    end
  end

  describe "#reset!" do
    before do
      config.default_description_source = :stripe
      config.include_reserved_ranges = true
      config.cache_enabled = false
      config.data_path = "/custom/path"
      config.logger = Logger.new($stdout)
    end

    it "resets default_description_source to :iso" do
      config.reset!
      expect(config.default_description_source).to eq(:iso)
    end

    it "resets include_reserved_ranges to false" do
      config.reset!
      expect(config.include_reserved_ranges).to be(false)
    end

    it "resets cache_enabled to true" do
      config.reset!
      expect(config.cache_enabled).to be(true)
    end

    it "resets data_path to default" do
      config.reset!
      expect(config.data_path).to eq(config.default_data_path)
    end

    it "resets logger to nil" do
      config.reset!
      expect(config.logger).to be_nil
    end

    it "returns self" do
      expect(config.reset!).to eq(config)
    end
  end

  describe "#to_h" do
    it "returns a hash representation" do
      hash = config.to_h

      expect(hash).to be_a(Hash)
    end

    it "includes default_description_source" do
      hash = config.to_h

      expect(hash[:default_description_source]).to eq(:iso)
    end

    it "includes include_reserved_ranges" do
      hash = config.to_h

      expect(hash[:include_reserved_ranges]).to be(false)
    end

    it "includes cache_enabled" do
      hash = config.to_h

      expect(hash[:cache_enabled]).to be(true)
    end

    it "includes data_path" do
      hash = config.to_h

      expect(hash[:data_path]).to eq(config.data_path)
    end

    it "does not include logger" do
      hash = config.to_h

      expect(hash).not_to have_key(:logger)
    end

    it "reflects current configuration values" do
      config.default_description_source = :stripe
      config.cache_enabled = false

      hash = config.to_h

      expect(hash[:default_description_source]).to eq(:stripe)
      expect(hash[:cache_enabled]).to be(false)
    end
  end

  describe "DESCRIPTION_SOURCES constant" do
    it "contains expected sources" do
      expected = %i[iso usda stripe visa mastercard amex alipay irs]

      expect(described_class::DESCRIPTION_SOURCES).to eq(expected)
    end

    it "is frozen" do
      expect(described_class::DESCRIPTION_SOURCES).to be_frozen
    end
  end

  describe "integration with Elia::Mcc module" do
    it "can be configured via block" do
      Elia::Mcc.configure do |c|
        c.default_description_source = :stripe
        c.cache_enabled = false
      end

      expect(Elia::Mcc.configuration.default_description_source).to eq(:stripe)
      expect(Elia::Mcc.configuration.cache_enabled).to be(false)
    end

    it "can be accessed directly" do
      expect(Elia::Mcc.configuration).to be_a(described_class)
    end

    it "resets with Elia::Mcc.reset!" do
      Elia::Mcc.configure { |c| c.default_description_source = :stripe }
      Elia::Mcc.reset!

      expect(Elia::Mcc.configuration.default_description_source).to eq(:iso)
    end
  end
end
