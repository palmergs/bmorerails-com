# Site-wide facts that appear in more than one place. Editing them here beats
# hunting through views. Kept as plain constants on purpose — no YAML, no
# database, nothing to migrate.
module Site
  NAME = "Bmore on Rails"
  TAGLINE = "Baltimore's Ruby and Rails community"
  DESCRIPTION = "Bmore on Rails is a friendly, inclusive meetup for Ruby and " \
                "Rails developers in Baltimore. Talks, hack nights, and good " \
                "company — beginners genuinely welcome."

  LUMA_URL = "https://luma.com/cja7x708"
  GITHUB_URL = "https://github.com/bmoreonrails"
  CONTACT_EMAIL = "hello@bmoreonrails.com"

  # Where the code of conduct sends people who need to report something.
  # TODO: replace with the real reporting contact before launch.
  CONDUCT_EMAIL = "conduct@bmoreonrails.com"
end
