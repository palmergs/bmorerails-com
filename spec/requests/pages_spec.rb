require "rails_helper"

RSpec.describe "Pages", type: :request do
  describe "GET /" do
    it "renders the hero, events, and sponsors sections" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Baltimore's Ruby and&nbsp;Rails community")
      expect(response.body).to include('id="events"')
      expect(response.body).to include('id="sponsors"')
    end

    it "links to the Luma calendar" do
      get root_path

      expect(response.body).to include(Site::LUMA_URL)
    end

    it "renders every sponsor currently in the content file" do
      get root_path

      expect(Sponsor.all).to be_present
      Sponsor.all.each do |sponsor|
        expect(response.body).to include(ERB::Util.html_escape(sponsor.name))
        expect(response.body).to match(/sponsors\/#{sponsor.logo.split('.').first}/) if sponsor.logo?
      end
    end

    it "links to the code of conduct" do
      get root_path

      expect(response.body).to include(code_of_conduct_path)
    end
  end

  describe "GET /code-of-conduct" do
    it "renders and offers a way to report" do
      get code_of_conduct_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Code of Conduct")
      expect(response.body).to include("mailto:#{Site::CONDUCT_EMAIL}")
    end

    it "points at the canonical policy" do
      get code_of_conduct_path

      expect(response.body).to include(Site::POLICY_URL)
    end

    # The anti-harassment policy is a document the group adopted, not copy we
    # are free to improve. This pins the rendered page to the canonical text so
    # a well-meaning edit can't quietly reword it. If the policy genuinely
    # changes, update it in the meetup repo first, then refresh this fixture.
    it "reproduces the adopted anti-harassment policy verbatim" do
      get code_of_conduct_path

      rendered = squish(strip_tags(response.body))

      expect(adopted_policy_paragraphs.size).to eq(4)
      adopted_policy_paragraphs.each do |paragraph|
        expect(rendered).to include(squish(paragraph))
      end
    end
  end

  def adopted_policy_paragraphs
    Rails.root.join("spec/fixtures/anti_harassment_policy.md")
      .read
      .split("\n\n")
      .map(&:strip)
      .reject { |line| line.blank? || line.start_with?("#", "Adapted from") }
  end

  def strip_tags(html)
    ActionController::Base.helpers.strip_tags(html)
  end

  def squish(text)
    CGI.unescapeHTML(text).gsub(/\s+/, " ").strip
  end
end
