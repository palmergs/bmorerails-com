# Site-wide facts that appear in more than one place. Editing them here beats
# hunting through views. Kept as plain constants on purpose — no YAML, no
# database, nothing to migrate.
module Site
  NAME = "Bmore on Rails"
  TAGLINE = "Baltimore's Ruby and Rails community"
  DESCRIPTION = "Bmore on Rails is a friendly, inclusive meetup for Ruby and " \
                "Rails developers in Baltimore. Talks, hack nights, and good " \
                "company — beginners genuinely welcome."

  # The calendar, not an individual event. Luma's short codes like /cja7x708
  # are single events; the calendar lives at its slug. Its API id, needed for
  # the iCal feed, is cal-dlH2sPWE7XDrZUW.
  LUMA_URL = "https://luma.com/bmore-on-rails"
  GITHUB_URL = "https://github.com/bmoreonrails"
  CONTACT_EMAIL = "hello@bmoreonrails.com"

  # The group's adopted anti-harassment policy. This is the canonical text —
  # the code of conduct page quotes it verbatim rather than paraphrasing it.
  POLICY_URL = "https://github.com/bmoreonrails/meetup/blob/main/anti_harassment_policy.md"
  POLICY_SOURCE_URL = "https://geekfeminism.fandom.com/wiki/Conference_anti-harassment/Policy"

  # Where the code of conduct sends people who need to report something.
  # TODO: replace with the real reporting contact before launch. The adopted
  # policy says "contact a member of meetup organizers" and names no address,
  # so this one is invented and needs an organizer to claim it.
  CONDUCT_EMAIL = "conduct@bmoreonrails.com"
end
