# The hand-maintained half of an event.
#
# Luma's iCal feed carries title, start, end, and a link — but its LOCATION is
# a bare street address (or, when nobody set one, a URL), and its DESCRIPTION
# is templated boilerplate rather than the event's real copy. Rather than pay
# for the API or scrape the site for those three fields, we keep them here.
#
# In practice the meetup is at the same place every month, so `defaults` covers
# nearly everything and per-event entries are the exception.
class EventDetails
  CONTENT_PATH = Rails.root.join("config/content/event_details.yml")

  KEYS = %i[venue neighborhood summary].freeze

  # Keyed by the Luma short code — the tail of https://luma.com/cja7x708.
  def self.for(url)
    slug = url.to_s.split("/").last
    overrides = slug.present? ? events.fetch(slug, {}) : {}

    defaults.merge(overrides).symbolize_keys.slice(*KEYS)
  end

  def self.defaults
    content["defaults"] || {}
  end

  def self.events
    content["events"] || {}
  end

  def self.content
    YAML.safe_load_file(CONTENT_PATH) || {}
  rescue Errno::ENOENT
    {}
  end

  private_class_method :defaults, :events, :content
end
