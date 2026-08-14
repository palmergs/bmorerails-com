# bmoreonrails.com

The website for [Bmore on Rails](https://luma.com/bmore-on-rails), Baltimore's Ruby
and Rails meetup.

Rails 8.1 · Ruby 4.0 · Tailwind CSS 4 · Hotwire · deployed with Kamal.

## Running it locally

```sh
bin/setup          # installs gems, prepares the database
bin/dev            # http://localhost:3000
```

## Editing the site without writing Ruby

Most changes don't need code. Content lives in plain YAML and one Ruby file:

| What | Where |
| --- | --- |
| Upcoming events | `config/content/events.yml` |
| Sponsors | `config/content/sponsors.yml` |
| Site name, links, contact addresses | `app/models/site.rb` |
| Code of conduct text | `app/views/pages/code_of_conduct.html.erb` |
| Colors and fonts | `app/assets/tailwind/application.css` |

Sponsor logos go in `app/assets/images/sponsors/`, referenced by filename in
`sponsors.yml`. A sponsor without a logo renders as a wordmark, which is a fine
state to ship — no placeholder boxes.

`events.yml` holds real data pulled from the Luma calendar. `sponsors.yml`
holds the three sponsors carried over from the old bmoreonrails.org, whose
list was last edited in 2018 — **confirm them before launch**. Both files
carry a note at the top explaining their state.

## Events and Luma

Events are hand-maintained in YAML today. The plan is to read them from Luma's
iCal feed, which is public, unauthenticated, and officially supported:

```
https://api.lu.ma/ics/get?entity=calendar&id=cal-dlH2sPWE7XDrZUW
```

`app/models/event.rb` documents the seam: replace the body of `Event.all` and
leave the public interface alone. The feed gives us title, start, end, and the
event URL; venue, neighborhood, and real prose stay in a small hand-maintained
overlay, because the feed's `LOCATION` is a bare street address and its
`DESCRIPTION` is templated boilerplate.

Whatever we build has to fall back to the YAML file when Luma is unreachable —
the events section already has a designed empty state for exactly that case.

Note that `luma.com/bmore-on-rails` is the **calendar**; short codes like
`luma.com/cja7x708` are individual events.

## Tests

```sh
bundle exec rspec
```

Request specs cover every page; model specs cover the content loaders. Content
specs read from `spec/fixtures/content/`, not the real site content, so editing
`config/content/*.yml` can never break the suite.

## Checks

```sh
bundle exec rubocop        # style
bin/brakeman               # security
bin/bundler-audit          # vulnerable gems
```

## Deployment

Kamal, configured in `config/deploy.yml`.

```sh
bin/kamal setup            # first time
bin/kamal deploy
```
