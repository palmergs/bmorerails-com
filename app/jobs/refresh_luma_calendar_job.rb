# Keeps the Luma cache warm out of band, so no visitor ever waits on Luma.
#
# Scheduled in config/recurring.yml. Luma's feed advertises a 12 hour refresh
# interval and the meetup is monthly, so nothing here is time critical — the
# point is simply that the cache is never cold when someone loads the page.
class RefreshLumaCalendarJob < ApplicationJob
  queue_as :default

  def perform
    events = Luma::Calendar.refresh

    if events.present?
      Rails.logger.info("[Luma] refreshed #{events.size} events")
    else
      Rails.logger.warn("[Luma] refresh returned nothing; serving fallbacks")
    end
  end
end
