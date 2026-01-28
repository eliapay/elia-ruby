# frozen_string_literal: true

RSpec.describe Elia::Mcc::Category do
  describe "#initialize" do
    context "with valid attributes" do
      let(:category) do
        described_class.new(
          id: :gambling,
          name: "Gambling",
          description: "Casinos, betting, lottery, and gaming",
          codes: %w[7800 7801 7802 7995 9406]
        )
      end

      it "sets the id attribute as a symbol" do
        expect(category.id).to eq(:gambling)
      end

      it "sets the name attribute" do
        expect(category.name).to eq("Gambling")
      end

      it "sets the description attribute" do
        expect(category.description).to eq("Casinos, betting, lottery, and gaming")
      end

      it "sets the codes attribute" do
        expect(category.codes).to eq(%w[7800 7801 7802 7995 9406])
      end
    end

    context "with string id" do
      let(:category) { described_class.new(id: "gambling", name: "Gambling", codes: []) }

      it "converts id to symbol" do
        expect(category.id).to eq(:gambling)
      end
    end

    context "with string keys" do
      let(:category) do
        described_class.new(
          "id" => :gambling,
          "name" => "Gambling",
          "description" => "Gaming activities",
          "codes" => ["7995"]
        )
      end

      it "converts string keys to symbols" do
        expect(category.id).to eq(:gambling)
        expect(category.name).to eq("Gambling")
        expect(category.description).to eq("Gaming activities")
        expect(category.codes).to eq(["7995"])
      end
    end

    context "with codes containing ranges" do
      let(:category) do
        described_class.new(
          id: :airlines,
          name: "Airlines",
          codes: %w[3000-3350 4511]
        )
      end

      it "stores range strings as-is" do
        expect(category.codes).to include("3000-3350")
        expect(category.codes).to include("4511")
      end
    end

    context "with nil or empty codes" do
      it "defaults to empty array for nil" do
        category = described_class.new(id: :test, name: "Test", codes: nil)
        expect(category.codes).to eq([])
      end

      it "accepts empty array" do
        category = described_class.new(id: :test, name: "Test", codes: [])
        expect(category.codes).to eq([])
      end
    end

    context "with integer codes" do
      let(:category) do
        described_class.new(
          id: :test,
          name: "Test",
          codes: [7995, 7800]
        )
      end

      it "converts integer codes to strings" do
        expect(category.codes).to eq(%w[7995 7800])
      end
    end
  end

  describe "#include?" do
    context "with individual codes" do
      let(:category) do
        described_class.new(
          id: :gambling,
          name: "Gambling",
          codes: %w[7800 7801 7802 7995 9406]
        )
      end

      it "returns true for codes in the category" do
        expect(category.include?("7995")).to be(true)
        expect(category.include?("7800")).to be(true)
      end

      it "returns false for codes not in the category" do
        expect(category.include?("5411")).to be(false)
        expect(category.include?("0742")).to be(false)
      end

      it "accepts integer codes" do
        expect(category.include?(7995)).to be(true)
        expect(category.include?(5411)).to be(false)
      end

      it "accepts Code objects" do
        code = Elia::Mcc::Code.new(mcc: "7995")
        expect(category.include?(code)).to be(true)

        non_gambling_code = Elia::Mcc::Code.new(mcc: "5411")
        expect(category.include?(non_gambling_code)).to be(false)
      end
    end

    context "with code ranges" do
      let(:category) do
        described_class.new(
          id: :airlines,
          name: "Airlines",
          codes: %w[3000-3350 4511]
        )
      end

      it "returns true for codes within the range" do
        expect(category.include?("3000")).to be(true)
        expect(category.include?("3100")).to be(true)
        expect(category.include?("3350")).to be(true)
      end

      it "returns false for codes outside the range" do
        expect(category.include?("2999")).to be(false)
        expect(category.include?("3351")).to be(false)
      end

      it "includes individual codes alongside ranges" do
        expect(category.include?("4511")).to be(true)
      end

      it "handles integer codes for ranges" do
        expect(category.include?(3100)).to be(true)
        expect(category.include?(2999)).to be(false)
      end
    end

    context "with multiple ranges" do
      let(:category) do
        described_class.new(
          id: :travel,
          name: "Travel",
          codes: %w[3351-3500 3501-3999 7011]
        )
      end

      it "checks all ranges" do
        expect(category.include?("3400")).to be(true)  # First range
        expect(category.include?("3600")).to be(true)  # Second range
        expect(category.include?("7011")).to be(true)  # Individual code
        expect(category.include?("3000")).to be(false) # Outside all
      end
    end

    context "with codes requiring normalization" do
      let(:category) do
        described_class.new(
          id: :test,
          name: "Test",
          codes: %w[742 700-750]
        )
      end

      it "normalizes codes with leading zeros" do
        expect(category.include?("0742")).to be(true)
        expect(category.include?(742)).to be(true)
        expect(category.include?("0720")).to be(true)
      end
    end
  end

  describe "#cover?" do
    it "is an alias for include?" do
      category = described_class.new(id: :gambling, name: "Gambling", codes: ["7995"])
      expect(category.cover?("7995")).to be(true)
      expect(category.cover?("5411")).to be(false)
    end
  end

  describe "#==" do
    let(:gambling_a) { described_class.new(id: :gambling, name: "Gambling 1", codes: ["7995"]) }
    let(:gambling_b) { described_class.new(id: :gambling, name: "Gambling 2", codes: %w[7995 7800]) }
    let(:healthcare) { described_class.new(id: :healthcare, name: "Healthcare", codes: ["8011"]) }

    it "returns true for categories with the same id" do
      expect(gambling_a == gambling_b).to be(true)
    end

    it "returns false for categories with different ids" do
      expect(gambling_a == healthcare).to be(false)
    end

    it "returns false when compared with non-Category objects" do
      expect(gambling_a == :gambling).to be(false)
      expect(gambling_a.nil?).to be(false)
    end
  end

  describe "#eql?" do
    it "behaves the same as ==" do
      cat1 = described_class.new(id: :gambling, name: "Gambling", codes: ["7995"])
      cat2 = described_class.new(id: :gambling, name: "Gambling 2", codes: [])

      expect(cat1.eql?(cat2)).to be(true)
    end
  end

  describe "#hash" do
    let(:gambling_a) { described_class.new(id: :gambling, name: "Gambling", codes: ["7995"]) }
    let(:gambling_b) { described_class.new(id: :gambling, name: "Gambling 2", codes: []) }
    let(:healthcare) { described_class.new(id: :healthcare, name: "Healthcare", codes: ["8011"]) }

    it "returns the same hash for categories with the same id" do
      expect(gambling_a.hash).to eq(gambling_b.hash)
    end

    it "returns different hashes for categories with different ids" do
      expect(gambling_a.hash).not_to eq(healthcare.hash)
    end

    it "can be used as hash keys" do
      hash = { gambling_a => "value" }
      expect(hash[gambling_b]).to eq("value")
    end
  end

  describe "#to_s" do
    it "returns the category name" do
      category = described_class.new(id: :gambling, name: "Gambling", codes: [])
      expect(category.to_s).to eq("Gambling")
    end
  end

  describe "#inspect" do
    let(:category) do
      described_class.new(
        id: :gambling,
        name: "Gambling",
        codes: %w[7800 7801 7995]
      )
    end

    it "returns a human-readable representation" do
      result = category.inspect

      expect(result).to include("Elia::Mcc::Category")
      expect(result).to include(":gambling")
      expect(result).to include("Gambling")
      expect(result).to include("codes_count=3")
    end
  end

  describe "#to_h" do
    let(:category) do
      described_class.new(
        id: :gambling,
        name: "Gambling",
        description: "Gaming activities",
        codes: %w[7800 7995]
      )
    end

    it "returns a hash representation" do
      hash = category.to_h

      expect(hash).to be_a(Hash)
      expect(hash[:id]).to eq(:gambling)
      expect(hash[:name]).to eq("Gambling")
      expect(hash[:description]).to eq("Gaming activities")
      expect(hash[:codes]).to eq(%w[7800 7995])
    end
  end

  describe "integration with loaded data" do
    it "correctly identifies codes in loaded categories" do
      categories = Elia::Mcc.categories

      expect(categories).not_to be_empty

      # Find the gambling category
      gambling = categories.find { |c| c.id == :gambling }
      expect(gambling).not_to be_nil
      expect(gambling.include?("7995")).to be(true)
      expect(gambling.include?("5411")).to be(false)
    end

    it "handles range-based categories correctly" do
      categories = Elia::Mcc.categories

      # Find the airlines category (has range 3000-3350)
      airlines = categories.find { |c| c.id == :airlines }
      expect(airlines).not_to be_nil
      expect(airlines.include?("3100")).to be(true)
      expect(airlines.include?("4511")).to be(true)
    end
  end
end
