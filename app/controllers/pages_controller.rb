class PagesController < ApplicationController
  def home
    @events = Event.upcoming
    @sponsors = Sponsor.all
  end

  def code_of_conduct
  end
end
