# frozen_string_literal: true

RSpec.describe Elia::Mcc::Code do
  describe "#initialize" do
    context "with valid attributes" do
      let(:code) do
        described_class.new(
          mcc: "5411",
          iso_description: "Grocery Stores, Supermarkets",
          usda_description: "Grocery Stores",
          stripe_description: "Grocery Stores and Supermarkets",
          stripe_code: "grocery_stores_supermarkets",
          visa_description: "Grocery Stores, Supermarkets",
          visa_clearing_name: "GROCERY",
          mastercard_description: "Grocery Stores",
          amex_description: "Grocery Stores",
          alipay_description: "Grocery stores",
          irs_description: "Grocery Stores and Supermarkets",
          irs_reportable: true
        )
      end

      it "sets the mcc attribute" do
        expect(code.mcc).to eq("5411")
      end

      it "sets the iso_description attribute" do
        expect(code.iso_description).to eq("Grocery Stores, Supermarkets")
      end

      it "sets the usda_description attribute" do
        expect(code.usda_description).to eq("Grocery Stores")
      end

      it "sets the stripe_description attribute" do
        expect(code.stripe_description).to eq("Grocery Stores and Supermarkets")
      end

      it "sets the stripe_code attribute" do
        expect(code.stripe_code).to eq("grocery_stores_supermarkets")
      end

      it "sets the visa_description attribute" do
        expect(code.visa_description).to eq("Grocery Stores, Supermarkets")
      end

      it "sets the visa_clearing_name attribute" do
        expect(code.visa_clearing_name).to eq("GROCERY")
      end

      it "sets the mastercard_description attribute" do
        expect(code.mastercard_description).to eq("Grocery Stores")
      end

      it "sets the amex_description attribute" do
        expect(code.amex_description).to eq("Grocery Stores")
      end

      it "sets the alipay_description attribute" do
        expect(code.alipay_description).to eq("Grocery stores")
      end

      it "sets the irs_description attribute" do
        expect(code.irs_description).to eq("Grocery Stores and Supermarkets")
      end

      it "sets the irs_reportable attribute" do
        expect(code.irs_reportable).to be(true)
      end
    end

    context "with integer mcc" do
      let(:code) { described_class.new(mcc: 742) }

      it "normalizes to a 4-digit string with leading zeros" do
        expect(code.mcc).to eq("0742")
      end
    end

    context "with string keys" do
      let(:code) do
        described_class.new(
          "mcc" => "5411",
          "iso_description" => "Test Description"
        )
      end

      it "converts string keys to symbols" do
        expect(code.mcc).to eq("5411")
        expect(code.iso_description).to eq("Test Description")
      end
    end

    context "with blank descriptions" do
      let(:code) do
        described_class.new(
          mcc: "5411",
          iso_description: "",
          usda_description: "   "
        )
      end

      it "sets blank descriptions to nil" do
        expect(code.iso_description).to be_nil
        expect(code.usda_description).to be_nil
      end
    end

    context "with invalid mcc format" do
      it "raises InvalidCode for non-numeric values" do
        expect { described_class.new(mcc: "ABCD") }.to raise_error(Elia::Mcc::InvalidCode)
      end

      it "raises InvalidCode for codes longer than 4 digits" do
        expect { described_class.new(mcc: "12345") }.to raise_error(Elia::Mcc::InvalidCode)
      end

      it "normalizes empty strings to 0000" do
        # Empty string becomes "0000" after rjust(4, "0")
        code = described_class.new(mcc: "")
        expect(code.mcc).to eq("0000")
      end
    end
  end

  describe "#irs_reportable?" do
    it "returns true when irs_reportable is true" do
      code = described_class.new(mcc: "5411", irs_reportable: true)
      expect(code.irs_reportable?).to be(true)
    end

    it "returns false when irs_reportable is false" do
      code = described_class.new(mcc: "5411", irs_reportable: false)
      expect(code.irs_reportable?).to be(false)
    end

    it "returns false when irs_reportable is nil" do
      code = described_class.new(mcc: "5411", irs_reportable: nil)
      expect(code.irs_reportable?).to be(false)
    end

    it "returns false when irs_reportable is not set" do
      code = described_class.new(mcc: "5411")
      expect(code.irs_reportable?).to be(false)
    end
  end

  describe "#description" do
    context "with default source" do
      let(:code) do
        described_class.new(
          mcc: "5411",
          iso_description: "ISO Description",
          stripe_description: "Stripe Description"
        )
      end

      it "returns the ISO description by default" do
        expect(code.description).to eq("ISO Description")
      end
    end

    context "with specified source" do
      let(:code) do
        described_class.new(
          mcc: "5411",
          iso_description: "ISO Description",
          stripe_description: "Stripe Description"
        )
      end

      it "returns the stripe description when specified" do
        expect(code.description(source: :stripe)).to eq("Stripe Description")
      end

      it "returns the iso description when specified" do
        expect(code.description(source: :iso)).to eq("ISO Description")
      end
    end

    context "with fallback behavior" do
      let(:code) do
        described_class.new(
          mcc: "5411",
          iso_description: nil,
          usda_description: "USDA Description"
        )
      end

      it "falls back to other sources when default is blank" do
        expect(code.description).to eq("USDA Description")
      end
    end

    context "when all descriptions are blank" do
      let(:code) { described_class.new(mcc: "5411") }

      it "returns nil" do
        expect(code.description).to be_nil
      end
    end

    context "with custom configuration" do
      before do
        Elia::Mcc.configure do |config|
          config.default_description_source = :stripe
        end
      end

      let(:code) do
        described_class.new(
          mcc: "5411",
          iso_description: "ISO Description",
          stripe_description: "Stripe Description"
        )
      end

      it "uses the configured default source" do
        expect(code.description).to eq("Stripe Description")
      end
    end
  end

  describe "#range" do
    it "returns the range containing this code" do
      code = Elia::Mcc.find("5411")
      range = code.range

      expect(range).to be_a(Elia::Mcc::Range)
      expect(range.include?(code.mcc)).to be(true)
    end
  end

  describe "#categories" do
    it "returns all categories containing this code" do
      code = Elia::Mcc.find("5411")
      categories = code.categories

      expect(categories).to be_an(Array)
      expect(categories.all? { |c| c.is_a?(Elia::Mcc::Category) }).to be(true)
    end

    it "returns categories that include the code" do
      code = Elia::Mcc.find("7995")
      categories = code.categories

      expect(categories.map(&:id)).to include(:gambling)
    end
  end

  describe "#in_category?" do
    let(:code) { Elia::Mcc.find("7995") }

    context "with Category object" do
      it "returns true when code is in category" do
        gambling_category = Elia::Mcc.categories.find { |c| c.id == :gambling }
        expect(code.in_category?(gambling_category)).to be(true)
      end
    end

    context "with Symbol" do
      it "returns true when code is in category" do
        expect(code.in_category?(:gambling)).to be(true)
      end

      it "returns false when code is not in category" do
        expect(code.in_category?(:healthcare)).to be(false)
      end
    end

    context "with String" do
      it "returns true when code is in category" do
        expect(code.in_category?("gambling")).to be(true)
      end

      it "returns false when code is not in category" do
        expect(code.in_category?("healthcare")).to be(false)
      end
    end
  end

  describe "#to_h" do
    let(:code) do
      described_class.new(
        mcc: "5411",
        iso_description: "Grocery Stores",
        stripe_code: "grocery_stores",
        irs_reportable: true
      )
    end

    it "returns a hash with all attributes" do
      hash = code.to_h

      expect(hash).to be_a(Hash)
      expect(hash[:mcc]).to eq("5411")
      expect(hash[:iso_description]).to eq("Grocery Stores")
      expect(hash[:stripe_code]).to eq("grocery_stores")
      expect(hash[:irs_reportable]).to be(true)
    end

    it "includes nil values for unset attributes" do
      hash = code.to_h

      expect(hash).to have_key(:usda_description)
      expect(hash[:usda_description]).to be_nil
    end
  end

  describe "#as_json" do
    let(:code) { Elia::Mcc.find("5411") }

    it "returns a JSON-compatible hash" do
      json = code.as_json

      expect(json).to be_a(Hash)
      expect(json[:mcc]).to eq("5411")
      expect(json).to have_key(:description)
      expect(json).to have_key(:categories)
      expect(json).to have_key(:range)
    end

    it "includes the description" do
      json = code.as_json

      expect(json[:description]).to eq(code.description)
    end

    it "includes category ids" do
      json = code.as_json

      expect(json[:categories]).to be_an(Array)
      expect(json[:categories].all? { |c| c.is_a?(Symbol) }).to be(true)
    end

    it "includes the range name" do
      json = code.as_json

      expect(json[:range]).to be_a(String) if json[:range]
    end
  end

  describe "#==" do
    let(:grocery_code_a) { described_class.new(mcc: "5411", iso_description: "Description 1") }
    let(:grocery_code_b) { described_class.new(mcc: "5411", iso_description: "Description 2") }
    let(:different_code) { described_class.new(mcc: "5412", iso_description: "Description 1") }

    it "returns true for codes with the same mcc" do
      expect(grocery_code_a == grocery_code_b).to be(true)
    end

    it "returns false for codes with different mcc" do
      expect(grocery_code_a == different_code).to be(false)
    end

    it "compares with string values" do
      expect(grocery_code_a == "5411").to be(true)
      expect(grocery_code_a == "5412").to be(false)
    end

    it "compares with integer values" do
      expect(grocery_code_a == 5411).to be(true)
      expect(grocery_code_a == 5412).to be(false)
    end

    it "handles comparison with normalized integer" do
      code = described_class.new(mcc: 742)
      expect(code == 742).to be(true)
      expect(code == "0742").to be(true)
    end

    it "returns false for non-comparable types" do
      expect(grocery_code_a.nil?).to be(false)
      expect(grocery_code_a == []).to be(false)
    end
  end

  describe "#eql?" do
    it "behaves the same as ==" do
      code1 = described_class.new(mcc: "5411")
      code2 = described_class.new(mcc: "5411")

      expect(code1.eql?(code2)).to be(true)
    end
  end

  describe "#hash" do
    let(:grocery_code_a) { described_class.new(mcc: "5411") }
    let(:grocery_code_b) { described_class.new(mcc: "5411") }
    let(:different_code) { described_class.new(mcc: "5412") }

    it "returns the same hash for equal codes" do
      expect(grocery_code_a.hash).to eq(grocery_code_b.hash)
    end

    it "returns different hashes for different codes" do
      expect(grocery_code_a.hash).not_to eq(different_code.hash)
    end

    it "can be used as hash keys" do
      hash = { grocery_code_a => "value" }
      expect(hash[grocery_code_b]).to eq("value")
    end
  end

  describe "#to_i" do
    it "returns the numeric value of the code" do
      code = described_class.new(mcc: "5411")
      expect(code.to_i).to eq(5411)
    end

    it "handles codes with leading zeros" do
      code = described_class.new(mcc: "0742")
      expect(code.to_i).to eq(742)
    end
  end

  describe "#to_s" do
    it "returns the 4-digit code string" do
      code = described_class.new(mcc: "5411")
      expect(code.to_s).to eq("5411")
    end

    it "preserves leading zeros" do
      code = described_class.new(mcc: 742)
      expect(code.to_s).to eq("0742")
    end
  end

  describe "#inspect" do
    let(:code) do
      described_class.new(
        mcc: "5411",
        iso_description: "Grocery Stores"
      )
    end

    it "returns a human-readable representation" do
      result = code.inspect

      expect(result).to include("Elia::Mcc::Code")
      expect(result).to include("5411")
      expect(result).to include("Grocery Stores")
    end
  end
end
