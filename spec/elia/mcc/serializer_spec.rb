# frozen_string_literal: true

require "json"

RSpec.describe Elia::Mcc::Serializer do
  describe ".serialize_code" do
    let(:code) { Elia::Mcc.find("5411") }

    context "with default options" do
      let(:result) { described_class.serialize_code(code) }

      it "returns a hash" do
        expect(result).to be_a(Hash)
      end

      it "includes the mcc" do
        expect(result[:mcc]).to eq("5411")
      end

      it "includes the description" do
        expect(result[:description]).to eq(code.description)
      end

      it "includes the stripe_code" do
        expect(result[:stripe_code]).to eq(code.stripe_code)
      end

      it "includes irs_reportable" do
        expect(result[:irs_reportable]).to eq(code.irs_reportable?)
      end

      it "includes categories by default" do
        expect(result).to have_key(:categories)
        expect(result[:categories]).to be_an(Array)
      end

      it "includes range by default" do
        expect(result).to have_key(:range)
      end

      it "does not include all descriptions by default" do
        expect(result).not_to have_key(:iso_description)
        expect(result).not_to have_key(:usda_description)
        expect(result).not_to have_key(:visa_description)
      end
    end

    context "with include_all_descriptions: true" do
      let(:result) { described_class.serialize_code(code, include_all_descriptions: true) }

      it "includes iso_description" do
        expect(result).to have_key(:iso_description)
        expect(result[:iso_description]).to eq(code.iso_description)
      end

      it "includes usda_description" do
        expect(result).to have_key(:usda_description)
        expect(result[:usda_description]).to eq(code.usda_description)
      end

      it "includes stripe_description" do
        expect(result).to have_key(:stripe_description)
        expect(result[:stripe_description]).to eq(code.stripe_description)
      end

      it "includes visa_description" do
        expect(result).to have_key(:visa_description)
        expect(result[:visa_description]).to eq(code.visa_description)
      end

      it "includes visa_clearing_name" do
        expect(result).to have_key(:visa_clearing_name)
        expect(result[:visa_clearing_name]).to eq(code.visa_clearing_name)
      end

      it "includes mastercard_description" do
        expect(result).to have_key(:mastercard_description)
        expect(result[:mastercard_description]).to eq(code.mastercard_description)
      end

      it "includes amex_description" do
        expect(result).to have_key(:amex_description)
        expect(result[:amex_description]).to eq(code.amex_description)
      end

      it "includes alipay_description" do
        expect(result).to have_key(:alipay_description)
        expect(result[:alipay_description]).to eq(code.alipay_description)
      end

      it "includes irs_description" do
        expect(result).to have_key(:irs_description)
        expect(result[:irs_description]).to eq(code.irs_description)
      end

      it "still includes basic fields" do
        expect(result[:mcc]).to eq("5411")
        expect(result[:description]).to eq(code.description)
      end
    end

    context "with include_categories: false" do
      let(:result) { described_class.serialize_code(code, include_categories: false) }

      it "does not include categories" do
        expect(result).not_to have_key(:categories)
      end

      it "still includes other fields" do
        expect(result[:mcc]).to eq("5411")
        expect(result[:description]).to eq(code.description)
      end
    end

    context "with include_range: false" do
      let(:result) { described_class.serialize_code(code, include_range: false) }

      it "does not include range" do
        expect(result).not_to have_key(:range)
      end

      it "still includes other fields" do
        expect(result[:mcc]).to eq("5411")
        expect(result[:description]).to eq(code.description)
      end
    end

    context "with all options disabled" do
      let(:result) do
        described_class.serialize_code(
          code,
          include_all_descriptions: false,
          include_categories: false,
          include_range: false
        )
      end

      it "returns minimal representation" do
        expect(result.keys).to contain_exactly(:mcc, :description, :stripe_code, :irs_reportable)
      end
    end

    context "with code that has a range" do
      let(:code_with_range) { Elia::Mcc::Code.new(mcc: "5411") }
      let(:result) { described_class.serialize_code(code_with_range) }

      it "includes the range name" do
        # All codes 0000-9999 fall within some range, so range should always exist
        expect(result[:range]).to be_a(String)
      end
    end
  end

  describe ".serialize_category" do
    let(:category) { Elia::Mcc.categories.find { |c| c.id == :gambling } }

    context "with default options" do
      let(:result) { described_class.serialize_category(category) }

      it "returns a hash" do
        expect(result).to be_a(Hash)
      end

      it "includes the id" do
        expect(result[:id]).to eq(:gambling)
      end

      it "includes the name" do
        expect(result[:name]).to eq(category.name)
      end

      it "includes the description" do
        expect(result[:description]).to eq(category.description)
      end

      it "does not include codes by default" do
        expect(result).not_to have_key(:codes)
      end
    end

    context "with include_codes: true" do
      let(:result) { described_class.serialize_category(category, include_codes: true) }

      it "includes codes" do
        expect(result).to have_key(:codes)
        expect(result[:codes]).to eq(category.codes)
      end

      it "still includes other fields" do
        expect(result[:id]).to eq(:gambling)
        expect(result[:name]).to eq(category.name)
      end
    end
  end

  describe ".serialize_range" do
    let(:range) { Elia::Mcc.ranges.find { |r| r.name == "Agricultural Services" } }

    context "with default options" do
      let(:result) { described_class.serialize_range(range) }

      it "returns a hash" do
        expect(result).to be_a(Hash)
      end

      it "includes start_code" do
        expect(result[:start_code]).to eq(range.start_code)
      end

      it "includes end_code" do
        expect(result[:end_code]).to eq(range.end_code)
      end

      it "includes name" do
        expect(result[:name]).to eq(range.name)
      end

      it "includes description" do
        expect(result[:description]).to eq(range.description)
      end

      it "includes reserved" do
        expect(result[:reserved]).to eq(range.reserved?)
      end
    end

    context "with reserved range" do
      let(:reserved_range) { Elia::Mcc.ranges.find(&:reserved?) }
      let(:result) { described_class.serialize_range(reserved_range) }

      it "sets reserved to true" do
        expect(result[:reserved]).to be(true)
      end
    end

    context "with non-reserved range" do
      let(:non_reserved_range) { Elia::Mcc.ranges.find { |r| !r.reserved? } }
      let(:result) { described_class.serialize_range(non_reserved_range) }

      it "sets reserved to false" do
        expect(result[:reserved]).to be(false)
      end
    end

    context "when options parameter is provided" do
      let(:result) { described_class.serialize_range(range, some_option: true) }

      it "does not affect output" do
        expect(result).to have_key(:start_code)
        expect(result).to have_key(:end_code)
        expect(result).to have_key(:name)
        expect(result).to have_key(:description)
        expect(result).to have_key(:reserved)
      end
    end
  end

  describe ".serialize_collection" do
    let(:codes) { Elia::Mcc.all.first(3) }

    context "with default options" do
      let(:result) { described_class.serialize_collection(codes) }

      it "returns an array" do
        expect(result).to be_an(Array)
      end

      it "returns same number of elements" do
        expect(result.length).to eq(3)
      end

      it "serializes each code" do
        result.each_with_index do |hash, index|
          expect(hash[:mcc]).to eq(codes[index].mcc)
        end
      end

      it "includes categories for each code" do
        expect(result).to all(have_key(:categories))
      end

      it "includes range for each code" do
        expect(result).to all(have_key(:range))
      end
    end

    context "with options passed through" do
      let(:result) do
        described_class.serialize_collection(
          codes,
          include_all_descriptions: true,
          include_categories: false
        )
      end

      it "applies options to each code" do
        result.each do |hash|
          expect(hash).to have_key(:iso_description)
          expect(hash).not_to have_key(:categories)
        end
      end
    end

    context "with empty collection" do
      let(:result) { described_class.serialize_collection([]) }

      it "returns empty array" do
        expect(result).to eq([])
      end
    end

    context "with single code" do
      let(:single_code) { [Elia::Mcc.find("5411")] }
      let(:result) { described_class.serialize_collection(single_code) }

      it "returns array with single element" do
        expect(result.length).to eq(1)
        expect(result.first[:mcc]).to eq("5411")
      end
    end
  end

  describe "JSON compatibility" do
    it "produces JSON-compatible output for codes" do
      code = Elia::Mcc.find("5411")
      result = described_class.serialize_code(code)

      expect { JSON.generate(result) }.not_to raise_error
    end

    it "produces JSON-compatible output for categories" do
      category = Elia::Mcc.categories.first
      result = described_class.serialize_category(category, include_codes: true)

      expect { JSON.generate(result) }.not_to raise_error
    end

    it "produces JSON-compatible output for ranges" do
      range = Elia::Mcc.ranges.first
      result = described_class.serialize_range(range)

      expect { JSON.generate(result) }.not_to raise_error
    end

    it "produces JSON-compatible output for collections" do
      codes = Elia::Mcc.all.first(5)
      result = described_class.serialize_collection(codes)

      expect { JSON.generate(result) }.not_to raise_error
    end
  end

  describe "consistency with Code#as_json" do
    let(:code) { Elia::Mcc.find("5411") }

    it "produces similar structure to Code#as_json" do
      serialized = described_class.serialize_code(code, include_all_descriptions: true)
      as_json = code.as_json

      # Both should have these core fields
      expect(serialized[:mcc]).to eq(as_json[:mcc])
      expect(serialized[:description]).to eq(as_json[:description])
      expect(serialized[:categories]).to eq(as_json[:categories])
      expect(serialized[:range]).to eq(as_json[:range])
    end
  end
end
