require "net/http"

module Luma
  # Reads the B'more on Rails calendar from Luma's public iCal feed.
  #
  # The feed is unauthenticated and officially supported (it is what Luma's own
  # "Add iCal Subscription" button produces), so there is no API key to manage
  # and no paid plan involved. It advertises REFRESH-INTERVAL:PT12H and sends
  # no ETag or Last-Modified, which rules out conditional requests — we own the
  # caching entirely.
  #
  # Failure is the interesting case. Three tiers, in order:
  #
  #   1. fresh cache      — normal operation
  #   2. last-good cache  — Luma is down; serve what we last saw
  #   3. nil              — caller falls back to config/content/events.yml
  #
  # Nothing here raises. A meetup homepage must not 500 because a third party
  # is having a bad afternoon.
  class Calendar
    # Luma answered, but not with a calendar.
    class FeedUnavailable < StandardError; end

    # Things that go wrong when you talk to someone else's server. These are
    # expected, and they are what the fallback chain exists for. Anything else
    # is a bug in this file and should not be quietly swallowed in development
    # — see the rescue in .refresh.
    NETWORK_ERRORS = [
      Timeout::Error, SocketError, SystemCallError, IOError,
      OpenSSL::SSL::SSLError, Net::HTTPBadResponse, Net::ProtocolError,
      FeedUnavailable
    ].freeze

    FEED_URL = "https://api.lu.ma/ics/get?entity=calendar&id=cal-dlH2sPWE7XDrZUW".freeze

    FRESH_KEY = "luma:calendar:fresh".freeze
    LAST_GOOD_KEY = "luma:calendar:last_good".freeze

    FRESH_TTL = 6.hours
    LAST_GOOD_TTL = 30.days

    OPEN_TIMEOUT = 3
    READ_TIMEOUT = 5

    # Every title is suffixed with the calendar name, which is redundant on our
    # own site. Matches both straight and curly apostrophes.
    TITLE_SUFFIX = /\s*\|\s*B['’]more on Rails\s*\z/

    # The event's public page, which the feed only exposes inside DESCRIPTION.
    EVENT_URL = %r{https://luma\.com/[a-z0-9]+}

    # When nobody sets an address, Luma puts a URL in LOCATION. That is not a
    # venue and must never be rendered as one.
    URL_LOCATION = %r{\Ahttps?://}

    class << self
      # Cached event attributes, or nil when we have nothing to offer.
      def events
        cached = store.read(FRESH_KEY)
        return cached if cached

        refresh
      end

      # Fetches unconditionally and repopulates both caches. Called by
      # RefreshLumaCalendarJob so that a cold cache is rare and the network
      # stays off the request path. Returns nil on failure.
      def refresh
        payload = parse(download)
        return nil if payload.blank?

        store.write(FRESH_KEY, payload, expires_in: FRESH_TTL)
        store.write(LAST_GOOD_KEY, payload, expires_in: LAST_GOOD_TTL)
        payload
      rescue *NETWORK_ERRORS => error
        fall_back(error)
      rescue StandardError => error
        # Not an outage — a bug in this file, a missing gem, a feed that
        # changed shape. In development and test we want to see it immediately;
        # in production, keeping the site up matters more than being loud.
        raise unless Rails.env.production?

        fall_back(error)
      end

      def download
        uri = URI(FEED_URL)
        response = Net::HTTP.start(
          uri.host, uri.port,
          use_ssl: true, open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT
        ) { |http| http.get(uri.request_uri) }

        raise FeedUnavailable, "unexpected response #{response.code}" unless response.is_a?(Net::HTTPSuccess)

        response.body
      end

      private

      def fall_back(error)
        Rails.logger.warn("[Luma] refresh failed: #{error.class}: #{error.message}")
        store.read(LAST_GOOD_KEY)
      end

      def parse(body)
        calendars = Icalendar::Calendar.parse(body)
        calendars.flat_map(&:events).filter_map { |vevent| attributes_for(vevent) }
      end

      def attributes_for(vevent)
        starts_at = to_local(vevent.dtstart)
        return nil if starts_at.blank?

        title = vevent.summary.to_s.sub(TITLE_SUFFIX, "").strip
        return nil if title.blank?

        url = vevent.description.to_s[EVENT_URL]

        # venue, neighborhood, and real prose are not in the feed in any usable
        # form, so they come from a small hand-maintained overlay. A curated
        # venue name beats the feed's bare street address; the address is the
        # fallback for anything the overlay doesn't cover.
        details = EventDetails.for(url)

        {
          title: title,
          starts_at: starts_at,
          ends_at: to_local(vevent.dtend),
          url: url,
          venue: details[:venue].presence || venue_from(vevent),
          neighborhood: details[:neighborhood].presence,
          summary: details[:summary].presence
        }.compact
      end

      def venue_from(vevent)
        location = vevent.location.to_s.strip
        return nil if location.blank? || location.match?(URL_LOCATION)

        location
      end

      # DTSTART is UTC and drifts an hour across DST — 23:00Z in winter,
      # 00:00Z (the next day!) in summer, both meaning 7pm in Baltimore.
      # Convert, never truncate, or events land on the wrong day.
      def to_local(property)
        return nil if property.blank?

        property.to_time.in_time_zone(Time.zone)
      end

      # Rails.cache is a null store in development unless caching is toggled
      # on, which would mean hitting Luma on every single page render.
      #
      # The fallback is a file store rather than a memory store so that it is
      # shared between processes: `bin/rails runner 'Luma::Calendar.refresh'`
      # has to affect the server you already have running, or the console lies
      # to you about what the site is showing.
      def store
        return Rails.cache unless Rails.cache.is_a?(ActiveSupport::Cache::NullStore)

        @store ||= ActiveSupport::Cache::FileStore.new(Rails.root.join("tmp/cache/luma"))
      end
    end
  end
end
