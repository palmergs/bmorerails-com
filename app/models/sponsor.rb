# Sponsors, read from config/content/sponsors.yml.
#
# Adding a sponsor is a pull request, not a login: no admin UI, no auth, no
# uploads, no database. If that ever becomes the bottleneck, this class is the
# thing to back with ActiveRecord — the views only ask it for .all.
class Sponsor
  CONTENT_PATH = Rails.root.join("config/content/sponsors.yml")

  # Ordered strongest first; drives display order and card size.
  TIERS = %w[partner supporter friend].freeze

  attr_reader :name, :url, :tier, :blurb, :logo

  def self.all
    entries = YAML.safe_load_file(CONTENT_PATH) || []
    entries.map { |attributes| new(**attributes.symbolize_keys) }
      .sort_by { |sponsor| TIERS.index(sponsor.tier) || TIERS.length }
  rescue Errno::ENOENT
    []
  end

  def initialize(name:, url: nil, tier: "friend", blurb: nil, logo: nil)
    @name = name
    @url = url
    @tier = tier
    @blurb = blurb
    @logo = logo
  end

  # Logos are optional, and most of the time we won't have one yet. A clean
  # wordmark beats a broken image or an empty box.
  def logo?
    logo.present?
  end

  def partner?
    tier == "partner"
  end
end
