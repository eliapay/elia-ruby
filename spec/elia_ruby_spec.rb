# frozen_string_literal: true

RSpec.describe Elia do
  it "has a version number" do
    expect(Elia::VERSION).not_to be_nil
  end

  it "loads Elia::Mcc module" do
    expect(defined?(Elia::Mcc)).to eq("constant")
  end

  it "autoloads Elia::Mcc classes" do
    expect(Elia::Mcc::Code).to be_a(Class)
    expect(Elia::Mcc::Range).to be_a(Class)
    expect(Elia::Mcc::Category).to be_a(Class)
    expect(Elia::Mcc::Configuration).to be_a(Class)
  end
end
