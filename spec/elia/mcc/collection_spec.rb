# frozen_string_literal: true

RSpec.describe Elia::Mcc::Collection do
  let(:collection) { described_class.new }

  describe "#initialize" do
    it "creates an empty collection" do
      expect(collection.codes).to eq([])
      expect(collection.ranges).to eq([])
      expect(collection.categories).to eq([])
    end
  end

  describe "#all" do
    it "returns all MCC codes" do
      codes = collection.all

      expect(codes).to be_an(Array)
      expect(codes).not_to be_empty
      expect(codes.all? { |c| c.is_a?(Elia::Mcc::Code) }).to be(true)
    end

    it "loads data lazily" do
      new_collection = described_class.new
      expect(new_collection.codes).to eq([])

      # Trigger loading
      new_collection.all

      expect(new_collection.codes).not_to be_empty
    end

    it "returns consistent results on multiple calls" do
      first_call = collection.all
      second_call = collection.all

      expect(first_call).to eq(second_call)
    end
  end

  describe "#find" do
    it "finds a code by string" do
      code = collection.find("5411")

      expect(code).to be_a(Elia::Mcc::Code)
      expect(code.mcc).to eq("5411")
    end

    it "finds a code by integer" do
      code = collection.find(5411)

      expect(code).to be_a(Elia::Mcc::Code)
      expect(code.mcc).to eq("5411")
    end

    it "finds a code with leading zeros" do
      code = collection.find(742)

      expect(code).to be_a(Elia::Mcc::Code)
      expect(code.mcc).to eq("0742")
    end

    it "finds a code from string with leading zeros" do
      code = collection.find("0742")

      expect(code).to be_a(Elia::Mcc::Code)
      expect(code.mcc).to eq("0742")
    end

    it "returns nil for non-existent codes" do
      code = collection.find("9999")

      expect(code).to be_nil
    end

    it "returns nil for invalid format" do
      code = collection.find("invalid")

      expect(code).to be_nil
    end
  end

  describe "#find!" do
    it "finds and returns a code" do
      code = collection.find!("5411")

      expect(code).to be_a(Elia::Mcc::Code)
      expect(code.mcc).to eq("5411")
    end

    it "raises NotFound for non-existent codes" do
      expect { collection.find!("9999") }.to raise_error(Elia::Mcc::NotFound)
    end
  end

  describe "#[]" do
    it "works as an alias for find" do
      code = collection["5411"]

      expect(code).to be_a(Elia::Mcc::Code)
      expect(code.mcc).to eq("5411")
    end

    it "returns nil for non-existent codes" do
      expect(collection["9999"]).to be_nil
    end
  end

  describe "#where" do
    it "filters codes by exact attribute match" do
      codes = collection.where(irs_reportable: true)

      expect(codes).not_to be_empty
      expect(codes.all?(&:irs_reportable?)).to be(true)
    end

    it "filters codes by regex match" do
      codes = collection.where(iso_description: /veterinary/i)

      expect(codes).not_to be_empty
      codes.each do |code|
        expect(code.iso_description).to match(/veterinary/i)
      end
    end

    it "filters codes by array of values" do
      valid_mccs = %w[5411 5412 5499]
      codes = collection.where(mcc: valid_mccs)

      expect(codes.length).to be <= 3
      codes.each do |code|
        expect(valid_mccs).to include(code.mcc)
      end
    end

    it "supports multiple conditions" do
      codes = collection.where(
        irs_reportable: true,
        iso_description: /store/i
      )

      codes.each do |code|
        expect(code.irs_reportable?).to be(true)
        expect(code.iso_description).to match(/store/i)
      end
    end

    it "returns empty array when no matches" do
      codes = collection.where(iso_description: /xyznonexistent/)

      expect(codes).to eq([])
    end

    it "returns all codes when no conditions given" do
      codes = collection.where({})

      expect(codes).to eq(collection.all)
    end
  end

  describe "#in_range" do
    it "returns codes within the specified range" do
      codes = collection.in_range("Agricultural Services")

      expect(codes).not_to be_empty
      codes.each do |code|
        code_num = code.mcc.to_i
        expect(code_num).to be_between(700, 999)
      end
    end

    it "returns codes for case-insensitive range name" do
      codes = collection.in_range("agricultural services")

      expect(codes).not_to be_empty
    end

    it "returns codes with symbol range name" do
      codes = collection.in_range(:airlines)

      expect(codes).not_to be_empty
    end

    it "returns empty array for non-existent range" do
      codes = collection.in_range("NonExistentRange")

      expect(codes).to eq([])
    end
  end

  describe "#search" do
    it "searches across all description fields" do
      codes = collection.search("grocery")

      expect(codes).not_to be_empty
      expect(codes.first.description.downcase).to include("grocer")
    end

    it "searches by MCC code" do
      codes = collection.search("5411")

      expect(codes).not_to be_empty
      expect(codes.map(&:mcc)).to include("5411")
    end

    it "searches by stripe_code" do
      codes = collection.search("veterinary_services")

      expect(codes).not_to be_empty
      expect(codes.any? { |c| c.stripe_code == "veterinary_services" }).to be(true)
    end

    it "performs case-insensitive search" do
      codes_lower = collection.search("grocery")
      codes_upper = collection.search("GROCERY")
      codes_mixed = collection.search("GrOcErY")

      expect(codes_lower).to eq(codes_upper)
      expect(codes_lower).to eq(codes_mixed)
    end

    it "returns all codes for empty query" do
      codes = collection.search("")

      expect(codes).to eq(collection.all)
    end

    it "returns all codes for whitespace-only query" do
      codes = collection.search("   ")

      expect(codes).to eq(collection.all)
    end

    it "returns empty array when no matches" do
      codes = collection.search("xyznonexistent123")

      expect(codes).to eq([])
    end
  end

  describe "#in_category" do
    it "returns codes in the specified category" do
      codes = collection.in_category(:gambling)

      expect(codes).not_to be_empty
      gambling_codes = %w[7800 7801 7802 7995 9406]
      codes.each do |code|
        expect(gambling_codes).to include(code.mcc)
      end
    end

    it "accepts string category id" do
      codes = collection.in_category("gambling")

      expect(codes).not_to be_empty
    end

    it "returns codes from range-based categories" do
      codes = collection.in_category(:airlines)

      expect(codes).not_to be_empty
      codes.each do |code|
        code_num = code.mcc.to_i
        # Airlines: 3000-3350, 4415, 4511
        valid = code_num.between?(3000, 3350) ||
                code_num == 4415 ||
                code_num == 4511
        expect(valid).to be(true)
      end
    end

    it "returns empty array for non-existent category" do
      codes = collection.in_category(:nonexistent)

      expect(codes).to eq([])
    end
  end

  describe "#all_ranges" do
    it "returns all ranges" do
      ranges = collection.all_ranges

      expect(ranges).to be_an(Array)
      expect(ranges).not_to be_empty
      expect(ranges.all? { |r| r.is_a?(Elia::Mcc::Range) }).to be(true)
    end
  end

  describe "#all_categories" do
    it "returns all categories" do
      categories = collection.all_categories

      expect(categories).to be_an(Array)
      expect(categories).not_to be_empty
      expect(categories.all? { |c| c.is_a?(Elia::Mcc::Category) }).to be(true)
    end
  end

  describe "#valid?" do
    it "returns true for existing codes" do
      expect(collection.valid?("5411")).to be(true)
      expect(collection.valid?("0742")).to be(true)
    end

    it "returns false for non-existing codes" do
      expect(collection.valid?("9999")).to be(false)
    end

    it "accepts integer codes" do
      expect(collection.valid?(5411)).to be(true)
      expect(collection.valid?(742)).to be(true)
    end
  end

  describe "#exists?" do
    it "is an alias for valid?" do
      expect(collection.exists?("5411")).to be(true)
      expect(collection.exists?("9999")).to be(false)
    end
  end

  describe "#count" do
    it "returns the number of codes" do
      count = collection.count

      expect(count).to be > 0
      expect(count).to eq(collection.all.size)
    end
  end

  describe "#size" do
    it "is an alias for count" do
      expect(collection.size).to eq(collection.count)
    end
  end

  describe "#reload!" do
    it "reloads data from YAML files" do
      # Load data first
      original_count = collection.count
      expect(original_count).to be > 0

      # Reload
      result = collection.reload!

      expect(result).to eq(collection)
      expect(collection.count).to eq(original_count)
    end

    it "clears cached data before reloading" do
      collection.all

      # Force index creation
      collection.find("5411")

      # Reload should clear the index
      collection.reload!

      # Should still work after reload
      expect(collection.find("5411")).not_to be_nil
    end
  end

  describe "caching behavior" do
    context "when caching is enabled" do
      before do
        Elia::Mcc.configure { |c| c.cache_enabled = true }
      end

      it "loads data only once" do
        new_collection = described_class.new

        # First call loads data
        first_all = new_collection.all

        # Verify data is loaded
        expect(first_all).not_to be_empty

        # Second call should return same cached data
        second_all = new_collection.all
        expect(second_all.object_id).to eq(first_all.object_id)
      end
    end

    context "when caching is disabled" do
      before do
        Elia::Mcc.configure { |c| c.cache_enabled = false }
      end

      it "reloads data on each access" do
        new_collection = described_class.new

        # First call
        first_all = new_collection.all

        # Second call should reload
        second_all = new_collection.all

        # Same content but could be different objects
        expect(second_all.map(&:mcc)).to eq(first_all.map(&:mcc))
      end
    end
  end

  describe "thread safety" do
    it "handles concurrent access safely" do
      threads = 10.times.map do
        Thread.new do
          coll = described_class.new
          100.times do
            coll.find("5411")
            coll.search("grocery")
          end
        end
      end

      expect { threads.each(&:join) }.not_to raise_error
    end
  end
end
