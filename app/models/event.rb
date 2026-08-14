# Meetup events.
#
# A meetup event, however we happen to know about it.
#
# Where they come from, in order:
#
#   1. Luma::Calendar        — the live iCal feed, cached
#   2. config/content/events.yml  — the fallback, when Luma gives us nothing
#   3. []                    — and the events section renders its empty state
#
# Views only ever talk to this class, never to Luma, so the source can change
# without touching a template. Nothing in that chain raises: an events section
# that 500s because a third party is down is worse than one showing slightly
# stale truth, which is worse than one that honestly says "nothing scheduled".
class Event
  CONTENT_PATH = Rails.root.join("config/content/events.yml")

  attr_reader :title, :starts_at, :ends_at, :venue, :neighborhood, :summary, :url

  # Luma first; the YAML file is what we fall back to when Luma has nothing to
  # give us. Luma::Calendar never raises, so this never raises either.
  def self.all
    entries = Luma::Calendar.events.presence || from_file
    entries.map { |attributes| new(**attributes.symbolize_keys) }
  end

  def self.from_file
    YAML.safe_load_file(CONTENT_PATH, permitted_classes: [ Date, Time ]) || []
  rescue Errno::ENOENT
    []
  end

  # The homepage shows a short list; the full calendar lives on Luma.
  def self.upcoming(limit: 3)
    all.select(&:upcoming?).sort_by(&:starts_at).first(limit)
  end

  def initialize(title:, starts_at:, ends_at: nil, venue: nil, neighborhood: nil, summary: nil, url: nil)
    @title = title
    @starts_at = parse_time(starts_at)
    @ends_at = parse_time(ends_at)
    @venue = venue
    @neighborhood = neighborhood
    @summary = summary
    @url = url
  end

  # An event stays "upcoming" for the whole of its day so that tonight's meetup
  # doesn't vanish from the site while people are still walking in.
  def upcoming?
    starts_at.present? && starts_at >= Time.current.beginning_of_day
  end

  def location
    [ venue, neighborhood ].compact_blank.join(" · ")
  end

  def time_range
    return starts_at.strftime("%-l:%M %p") if ends_at.blank?

    "#{starts_at.strftime('%-l:%M')}–#{ends_at.strftime('%-l:%M %p')}"
  end

  private

  # Strings arrive from YAML; Luma hands us real Time objects already.
  def parse_time(value)
    case value
    when nil, "" then nil
    when String then Time.zone.parse(value)
    else value.in_time_zone(Time.zone)
    end
  end
end
