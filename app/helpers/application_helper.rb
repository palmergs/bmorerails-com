module ApplicationHelper
  # Views set these with `content_for :title` / `content_for :description`.
  # Both fall back to site-wide copy so no page ever ships an empty card.
  def page_title
    return "#{Site::NAME} — #{Site::TAGLINE}" unless content_for?(:title)

    "#{content_for(:title)} · #{Site::NAME}"
  end

  def page_description
    content_for(:description).presence || Site::DESCRIPTION
  end
end
