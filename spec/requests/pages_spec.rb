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
    it "renders the policy and a reporting contact" do
      get code_of_conduct_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Code of Conduct")
      expect(response.body).to include("mailto:#{Site::CONDUCT_EMAIL}")
    end
  end
end
