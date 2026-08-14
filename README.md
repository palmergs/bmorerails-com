# bmoreonrails.com

The website for [Bmore on Rails](https://luma.com/bmore-on-rails), Baltimore's Ruby
and Rails meetup.

Rails 8.1 · Ruby 4.0 · Tailwind CSS 4 · Hotwire · deployed with Kamal.

> **An experiment from "Bring Your Own Tokens"** (August 13, 2026). This site was
> built live at that meetup as an experiment in coding with an LLM agent — the
> whole thing, from the Rails app skeleton to the Luma iCal integration and this
> README. Treat it accordingly: it works and it is tested, but nothing here has
> been through the usual amount of human deliberation. If something looks odd,
> that's a fair question to raise, not a decision to defend.

## Running it locally

```sh
bin/setup          # installs gems, prepares the database
bin/dev            # http://localhost:3000
```

## Editing the site without writing Ruby

Most changes don't need code. Content lives in plain YAML and one Ruby file:

| What | Where |
| --- | --- |
| Event venue / neighborhood / write-ups | `config/content/event_details.yml` |
| Fallback events, used when Luma is down | `config/content/events.yml` |
| Sponsors | `config/content/sponsors.yml` |
| Site name, links, contact addresses | `app/models/site.rb` |
| Code of conduct page | `app/views/pages/code_of_conduct.html.erb` (see below) |
| Colors and fonts | `app/assets/tailwind/application.css` |

Sponsor logos go in `app/assets/images/sponsors/`, referenced by filename in
`sponsors.yml`. A sponsor without a logo renders as a wordmark, which is a fine
state to ship — no placeholder boxes.

EcoMap is a confirmed current sponsor. The other three came from the old
bmoreonrails.org, whose sponsor list was last edited in 2018 — **confirm them
before launch**. `sponsors.yml` says so at the top.

## Events and Luma

Events come from Luma's public iCal feed. It needs no API key and no paid
plan — it is what Luma's own "Add iCal Subscription" button produces:

```
https://api.lu.ma/ics/get?entity=calendar&id=cal-dlH2sPWE7XDrZUW
```

`luma.com/bmore-on-rails` is the **calendar**; short codes like
`luma.com/cja7x708` are individual events.

**Where each field comes from.** The feed gives us title, start, end, and the
event URL. Venue, neighborhood, and real write-ups come from
`config/content/event_details.yml`, because the feed's `LOCATION` is a bare
street address (occasionally a URL) and its `DESCRIPTION` is templated
boilerplate. The meetup is at the same place every month, so the `defaults`
block in that file covers almost everything.

**Failure behavior.** `Luma::Calendar` never raises. It falls back in three
steps: fresh cache → last-good cache (30 days) → `config/content/events.yml` →
empty, which renders the events section's designed empty state. A Luma outage
can make the site stale; it cannot make it error.

**Caching.** Six-hour freshness, refreshed out of band every four hours by
`RefreshLumaCalendarJob` (see `config/recurring.yml`) so no visitor waits on
Luma. In development, where `Rails.cache` is a null store by default, the
calendar quietly uses a process-local memory store instead of refetching on
every render.

To see the live feed from a console:

```sh
bin/rails runner 'pp Luma::Calendar.refresh.first'
```

## Code of conduct

The anti-harassment policy on `/code-of-conduct` is **not ours to edit here**.
It is the text the group adopted, and it lives at
[bmoreonrails/meetup](https://github.com/bmoreonrails/meetup/blob/main/anti_harassment_policy.md).
The page quotes it verbatim, and a spec pins the rendered page to a recorded
copy in `spec/fixtures/anti_harassment_policy.md` so it cannot be reworded by
accident.

To change the policy: change it in that repo first, then update the fixture and
the page together. Everything else on that page — reporting guidance, expected
behavior, how the policy is interpreted — is site copy and can be edited freely.

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
