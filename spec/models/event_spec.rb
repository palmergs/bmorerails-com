require "rails_helper"

RSpec.describe Event do
  def build(**overrides)
    described_class.new(**{ title: "Hack Night", starts_at: "2026-09-09 18:30" }.merge(overrides))
  end

  it "parses times in Baltimore local time" do
    expect(build.starts_at.zone).to eq(Time.zone.parse("2026-09-09 18:30").zone)
  end

  it "joins venue and neighborhood for display" do
    event = build(venue: "Betamore", neighborhood: "Federal Hill")

    expect(event.location).to eq("Betamore · Federal Hill")
  end

  it "omits the separator when only one is present" do
    expect(build(venue: "Betamore").location).to eq("Betamore")
  end

  describe "#time_range" do
    it "shows a range when an end time is known" do
      expect(build(ends_at: "2026-09-09 20:30").time_range).to eq("6:30–8:30 PM")
    end

    it "falls back to the start time alone" do
      expect(build.time_range).to eq("6:30 PM")
    end
  end

  describe "#upcoming?" do
    it "keeps tonight's event visible while it is happening" do
      travel_to Time.zone.parse("2026-09-09 19:45") do
        expect(build).to be_upcoming
      end
    end

    it "drops events once the day is over" do
      travel_to Time.zone.parse("2026-09-10 09:00") do
        expect(build).not_to be_upcoming
      end
    end
  end

  describe ".upcoming" do
    before do
      stub_const("#{described_class}::CONTENT_PATH", Rails.root.join("spec/fixtures/content/events.yml"))
    end

    it "returns future events soonest first, dropping past ones" do
      travel_to Time.zone.parse("2026-08-13 12:00") do
        expect(described_class.upcoming.map(&:title)).to eq([ "First Up", "Second Up", "Third Up" ])
      end
    end

    it "honours the limit" do
      travel_to Time.zone.parse("2026-08-13 12:00") do
        expect(described_class.upcoming(limit: 2).map(&:title)).to eq([ "First Up", "Second Up" ])
      end
    end
  end

  describe ".all" do
    it "prefers Luma over the file when Luma has events" do
      allow(Luma::Calendar).to receive(:events)
        .and_return([ { title: "From Luma", starts_at: "2026-09-10 19:00" } ])

      expect(described_class.all.map(&:title)).to eq([ "From Luma" ])
    end

    it "falls back to the file when Luma has nothing" do
      allow(Luma::Calendar).to receive(:events).and_return(nil)
      stub_const("#{described_class}::CONTENT_PATH", Rails.root.join("spec/fixtures/content/events.yml"))

      expect(described_class.all.map(&:title)).to include("First Up")
    end

    it "returns an empty list rather than raising when the file is missing" do
      stub_const("#{described_class}::CONTENT_PATH", Rails.root.join("config/content/nope.yml"))

      expect(described_class.all).to eq([])
    end
  end
end
