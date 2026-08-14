require "rails_helper"

RSpec.describe Luma::Calendar do
  let(:cache) { ActiveSupport::Cache::MemoryStore.new }
  let(:feed) { Rails.root.join("spec/fixtures/luma_calendar.ics").read }

  before { allow(described_class).to receive(:store).and_return(cache) }

  def serve_feed
    allow(described_class).to receive(:download).and_return(feed)
  end

  describe "parsing the feed" do
    before { serve_feed }

    it "returns every event in the calendar" do
      expect(described_class.events.size).to eq(11)
    end

    it "strips the redundant calendar name from titles" do
      titles = described_class.events.map { |event| event[:title] }

      expect(titles).to include("We're Back!")
      expect(titles.grep(/B'more on Rails\z/)).to be_empty
      expect(titles.grep(/\|/)).to be_empty
    end

    it "pulls the event's public URL out of the description" do
      event = described_class.events.find { |e| e[:title] == "Bring Your Own Tokens Hack Night" }

      expect(event[:url]).to eq("https://luma.com/cja7x708")
    end

    it "converts UTC start times to Baltimore local time" do
      event = described_class.events.find { |e| e[:title] == "We're Back!" }

      expect(event[:starts_at].zone).to eq("EDT")
      expect(event[:starts_at].strftime("%Y-%m-%d %H:%M")).to eq("2025-10-09 19:00")
    end

    # The feed says 2025-11-14T00:00Z. Truncating the UTC date would put this
    # event on the 14th; it is actually 7pm on the 13th in Baltimore.
    it "does not shift events across midnight when the UTC date differs" do
      event = described_class.events.find { |e| e[:title].start_with?("Bring your computers") }

      expect(event[:starts_at].zone).to eq("EST")
      expect(event[:starts_at].strftime("%Y-%m-%d %H:%M")).to eq("2025-11-13 19:00")
    end

    it "keeps every event at 7pm local despite the UTC times differing" do
      local_times = described_class.events.map { |event| event[:starts_at].strftime("%H:%M") }

      expect(local_times.uniq).to eq([ "19:00" ])
    end

    it "fills venue and neighborhood from the overlay" do
      event = described_class.events.find { |e| e[:title] == "Bring Your Own Tokens Hack Night" }

      expect(event[:venue]).to eq("Miller's Court")
      expect(event[:neighborhood]).to eq("Charles Village")
    end

    it "never renders a URL as a venue" do
      venues = described_class.events.filter_map { |event| event[:venue] }

      expect(venues.grep(/http/)).to be_empty
    end

    it "ignores Luma's boilerplate description" do
      summaries = described_class.events.filter_map { |event| event[:summary] }

      expect(summaries.grep(/Get up-to-date information at/)).to be_empty
    end
  end

  describe "caching" do
    it "only downloads once while the cache is fresh" do
      serve_feed
      3.times { described_class.events }

      expect(described_class).to have_received(:download).once
    end

    it "refetches once the fresh window has passed" do
      serve_feed
      described_class.events
      travel(described_class::FRESH_TTL + 1.minute) { described_class.events }

      expect(described_class).to have_received(:download).twice
    end
  end

  describe "when Luma is unreachable" do
    it "serves the last good payload" do
      serve_feed
      good = described_class.events

      allow(described_class).to receive(:download).and_raise(Net::OpenTimeout)
      travel(described_class::FRESH_TTL + 1.minute) do
        expect(described_class.events).to eq(good)
      end
    end

    it "returns nil when it has never seen a good payload" do
      allow(described_class).to receive(:download).and_raise(Net::OpenTimeout)

      expect(described_class.events).to be_nil
    end

    it "returns nil rather than raising on a non-200 response" do
      allow(described_class).to receive(:download).and_call_original
      allow(Net::HTTP).to receive(:start).and_return(Net::HTTPServerError.new("1.1", "503", "Service Unavailable"))

      expect(described_class.events).to be_nil
    end

    # A missing gem or a typo is not an outage, and swallowing it cost us an
    # afternoon of debugging once already.
    it "re-raises programming errors outside production" do
      allow(described_class).to receive(:download).and_raise(NameError, "uninitialized constant Icalendar")

      expect { described_class.events }.to raise_error(NameError)
    end

    it "still swallows programming errors in production" do
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
      allow(described_class).to receive(:download).and_raise(NameError, "uninitialized constant Icalendar")

      expect(described_class.events).to be_nil
    end

    it "returns nil rather than raising on unparseable junk" do
      allow(described_class).to receive(:download).and_return("this is not an ics file")

      expect(described_class.events).to be_nil
    end
  end
end
