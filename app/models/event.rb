# Meetup events.
#
# LUMA SEAM ------------------------------------------------------------------
# Events currently come from config/content/events.yml, which someone edits by
# hand. The plan is to read them from Luma's iCal feed, which is public,
# unauthenticated, and officially supported:
#
#   https://api.lu.ma/ics/get?entity=calendar&id=cal-dlH2sPWE7XDrZUW
#
# Replace the body of .all with a call to a source object and keep this public
# interface intact:
#
#   def self.all
#     Luma::Calendar.fetch   # cached, with a YAML fallback when Luma is down
#   end
#
# Every view talks to Event and never to the source, so that swap stays local.
# Whatever we build must degrade to the YAML file: an events section that
# renders a spinner forever because Luma is unreachable is worse than one that
# renders slightly stale truth.
#
# Three things the feed will need handling for:
#   * DTSTART is UTC and shifts with DST — parse UTC, convert to the app zone,
#     and never truncate the UTC date or events land on the wrong day.
#   * SUMMARY carries a trailing " | B'more on Rails" that is redundant here.
#   * LOCATION is a bare street address (sometimes a URL, when nobody set one)
#     and DESCRIPTION is templated boilerplate — so venue, neighborhood, and
#     real prose still come from a small hand-maintained overlay.
# ----------------------------------------------------------------------------
class Event
  CONTENT_PATH = Rails.root.join("config/content/events.yml")

  attr_reader :title, :starts_at, :ends_at, :venue, :neighborhood, :summary, :url

  def self.all
    entries = YAML.safe_load_file(CONTENT_PATH, permitted_classes: [ Date, Time ]) || []
    entries.map { |attributes| new(**attributes.symbolize_keys) }
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

  def parse_time(value)
    return nil if value.blank?

    Time.zone.parse(value.to_s)
  end
end
