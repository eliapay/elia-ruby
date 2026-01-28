# frozen_string_literal: true

RSpec.describe Elia::Mcc::Range do
  describe "#initialize" do
    context "with valid attributes" do
      let(:range) do
        described_class.new(
          start: "5000",
          end: "5599",
          name: "Retail Outlets",
          description: "Retail outlets including wholesale and department stores",
          reserved: false
        )
      end

      it "sets the start_code attribute" do
        expect(range.start_code).to eq("5000")
      end

      it "sets the end_code attribute" do
        expect(range.end_code).to eq("5599")
      end

      it "sets the name attribute" do
        expect(range.name).to eq("Retail Outlets")
      end

      it "sets the description attribute" do
        expect(range.description).to eq("Retail outlets including wholesale and department stores")
      end

      it "sets the reserved attribute" do
        expect(range.reserved).to be(false)
      end
    end

    context "with integer codes" do
      let(:range) { described_class.new(start: 700, end: 999, name: "Test") }

      it "normalizes to 4-digit strings with leading zeros" do
        expect(range.start_code).to eq("0700")
        expect(range.end_code).to eq("0999")
      end
    end

    context "with start_code and end_code keys" do
      let(:range) do
        described_class.new(
          start_code: "5000",
          end_code: "5599",
          name: "Retail"
        )
      end

      it "accepts alternative key names" do
        expect(range.start_code).to eq("5000")
        expect(range.end_code).to eq("5599")
      end
    end

    context "with string keys" do
      let(:range) do
        described_class.new(
          "start" => "5000",
          "end" => "5599",
          "name" => "Retail"
        )
      end

      it "converts string keys to symbols" do
        expect(range.start_code).to eq("5000")
        expect(range.end_code).to eq("5599")
        expect(range.name).to eq("Retail")
      end
    end

    context "with reserved: true" do
      let(:range) { described_class.new(start: "0000", end: "0699", name: "Reserved", reserved: true) }

      it "sets reserved to true" do
        expect(range.reserved).to be(true)
      end
    end

    context "with invalid range" do
      it "raises InvalidRange when start > end" do
        expect do
          described_class.new(start: "5599", end: "5000", name: "Invalid")
        end.to raise_error(Elia::Mcc::InvalidRange)
      end
    end
  end

  describe "#include?" do
    let(:range) { described_class.new(start: "5000", end: "5599", name: "Retail") }

    context "with string codes" do
      it "returns true for codes within the range" do
        expect(range.include?("5000")).to be(true)
        expect(range.include?("5411")).to be(true)
        expect(range.include?("5599")).to be(true)
      end

      it "returns false for codes outside the range" do
        expect(range.include?("4999")).to be(false)
        expect(range.include?("5600")).to be(false)
        expect(range.include?("0742")).to be(false)
      end
    end

    context "with integer codes" do
      it "returns true for codes within the range" do
        expect(range.include?(5000)).to be(true)
        expect(range.include?(5411)).to be(true)
        expect(range.include?(5599)).to be(true)
      end

      it "returns false for codes outside the range" do
        expect(range.include?(4999)).to be(false)
        expect(range.include?(5600)).to be(false)
      end
    end

    context "with Code objects" do
      it "returns true for Code objects within the range" do
        code = Elia::Mcc::Code.new(mcc: "5411")
        expect(range.include?(code)).to be(true)
      end

      it "returns false for Code objects outside the range" do
        code = Elia::Mcc::Code.new(mcc: "0742")
        expect(range.include?(code)).to be(false)
      end
    end

    context "with leading zeros" do
      let(:range) { described_class.new(start: "0700", end: "0999", name: "Agricultural") }

      it "handles codes with leading zeros" do
        expect(range.include?("0742")).to be(true)
        expect(range.include?(742)).to be(true)
        expect(range.include?("742")).to be(true)
      end
    end
  end

  describe "#cover?" do
    it "is an alias for include?" do
      range = described_class.new(start: "5000", end: "5599", name: "Retail")
      expect(range.cover?("5411")).to be(true)
      expect(range.cover?("4999")).to be(false)
    end
  end

  describe "#reserved?" do
    it "returns true when reserved is true" do
      range = described_class.new(start: "0000", end: "0699", name: "Reserved", reserved: true)
      expect(range.reserved?).to be(true)
    end

    it "returns false when reserved is false" do
      range = described_class.new(start: "5000", end: "5599", name: "Retail", reserved: false)
      expect(range.reserved?).to be(false)
    end

    it "returns false when reserved is not set" do
      range = described_class.new(start: "5000", end: "5599", name: "Retail")
      expect(range.reserved?).to be(false)
    end
  end

  describe "#size" do
    it "returns the number of codes in the range" do
      range = described_class.new(start: "5000", end: "5009", name: "Small Range")
      expect(range.size).to eq(10)
    end

    it "returns 1 for single-code ranges" do
      range = described_class.new(start: "5411", end: "5411", name: "Single Code")
      expect(range.size).to eq(1)
    end
  end

  describe "#count" do
    it "is an alias for size" do
      range = described_class.new(start: "5000", end: "5009", name: "Small Range")
      expect(range.count).to eq(10)
    end
  end

  describe "#length" do
    it "is an alias for size" do
      range = described_class.new(start: "5000", end: "5009", name: "Small Range")
      expect(range.length).to eq(10)
    end
  end

  describe "#to_a" do
    it "returns all codes in the range as an array of strings" do
      range = described_class.new(start: "5000", end: "5002", name: "Small Range")
      expect(range.to_a).to eq(%w[5000 5001 5002])
    end

    it "includes leading zeros" do
      range = described_class.new(start: "0700", end: "0702", name: "Agricultural")
      expect(range.to_a).to eq(%w[0700 0701 0702])
    end
  end

  describe "#each" do
    let(:range) { described_class.new(start: "5000", end: "5002", name: "Small Range") }

    it "iterates over each code in the range" do
      codes = range.each.to_a
      expect(codes).to eq(%w[5000 5001 5002])
    end

    it "returns an enumerator if no block given" do
      expect(range.each).to be_an(Enumerator)
    end
  end

  describe "#==" do
    let(:retail_range_a) { described_class.new(start: "5000", end: "5599", name: "Retail 1") }
    let(:retail_range_b) { described_class.new(start: "5000", end: "5599", name: "Retail 2") }
    let(:different_range) { described_class.new(start: "5000", end: "5699", name: "Retail") }

    it "returns true for ranges with the same start and end codes" do
      expect(retail_range_a == retail_range_b).to be(true)
    end

    it "returns false for ranges with different codes" do
      expect(retail_range_a == different_range).to be(false)
    end

    it "returns false when compared with non-Range objects" do
      expect(retail_range_a == "5000-5599").to be(false)
      expect(retail_range_a.nil?).to be(false)
    end
  end

  describe "#eql?" do
    it "behaves the same as ==" do
      range1 = described_class.new(start: "5000", end: "5599", name: "Retail")
      range2 = described_class.new(start: "5000", end: "5599", name: "Retail 2")

      expect(range1.eql?(range2)).to be(true)
    end
  end

  describe "#hash" do
    let(:retail_range_a) { described_class.new(start: "5000", end: "5599", name: "Retail") }
    let(:retail_range_b) { described_class.new(start: "5000", end: "5599", name: "Retail 2") }
    let(:different_range) { described_class.new(start: "5000", end: "5699", name: "Retail") }

    it "returns the same hash for equal ranges" do
      expect(retail_range_a.hash).to eq(retail_range_b.hash)
    end

    it "returns different hashes for different ranges" do
      expect(retail_range_a.hash).not_to eq(different_range.hash)
    end

    it "can be used as hash keys" do
      hash = { retail_range_a => "value" }
      expect(hash[retail_range_b]).to eq("value")
    end
  end

  describe "#to_s" do
    it "returns a string representation of the range" do
      range = described_class.new(start: "5000", end: "5599", name: "Retail")
      expect(range.to_s).to eq("5000-5599")
    end
  end

  describe "#inspect" do
    let(:range) do
      described_class.new(
        start: "5000",
        end: "5599",
        name: "Retail Outlets",
        reserved: false
      )
    end

    it "returns a human-readable representation" do
      result = range.inspect

      expect(result).to include("Elia::Mcc::Range")
      expect(result).to include("5000")
      expect(result).to include("5599")
      expect(result).to include("Retail Outlets")
      expect(result).to include("reserved=false")
    end
  end

  describe "#to_h" do
    let(:range) do
      described_class.new(
        start: "5000",
        end: "5599",
        name: "Retail Outlets",
        description: "Retail stores",
        reserved: false
      )
    end

    it "returns a hash" do
      expect(range.to_h).to be_a(Hash)
    end

    it "includes start_code" do
      expect(range.to_h[:start_code]).to eq("5000")
    end

    it "includes end_code" do
      expect(range.to_h[:end_code]).to eq("5599")
    end

    it "includes name" do
      expect(range.to_h[:name]).to eq("Retail Outlets")
    end

    it "includes description" do
      expect(range.to_h[:description]).to eq("Retail stores")
    end

    it "includes reserved" do
      expect(range.to_h[:reserved]).to be(false)
    end
  end

  describe "integration with loaded data" do
    it "correctly identifies codes in loaded ranges" do
      ranges = Elia::Mcc.ranges

      expect(ranges).not_to be_empty

      # Find the Agricultural Services range (0700-0999)
      ag_range = ranges.find { |r| r.name == "Agricultural Services" }
      expect(ag_range).not_to be_nil
      expect(ag_range.include?("0742")).to be(true)
      expect(ag_range.include?("5411")).to be(false)
    end
  end
end
