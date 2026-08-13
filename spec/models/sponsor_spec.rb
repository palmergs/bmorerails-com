require "rails_helper"

RSpec.describe Sponsor do
  it "defaults to the friend tier" do
    expect(described_class.new(name: "Acme").tier).to eq("friend")
  end

  it "knows when it has no logo to show" do
    expect(described_class.new(name: "Acme")).not_to be_logo
    expect(described_class.new(name: "Acme", logo: "acme.svg")).to be_logo
  end

  describe ".all" do
    it "orders partners ahead of supporters and friends" do
      stub_const("#{described_class}::CONTENT_PATH", Rails.root.join("spec/fixtures/content/sponsors.yml"))

      expect(described_class.all.map(&:tier)).to eq(%w[partner supporter friend])
    end

    it "returns an empty list rather than raising when the file is missing" do
      stub_const("#{described_class}::CONTENT_PATH", Rails.root.join("config/content/nope.yml"))

      expect(described_class.all).to eq([])
    end
  end
end
