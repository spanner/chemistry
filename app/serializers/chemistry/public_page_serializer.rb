require "fast_jsonapi"

class Chemistry::PublicPageSerializer
  include FastJsonapi::ObjectSerializer

  set_type :page

  attributes :id,
             :path,
             :slug

  attribute :path, &:published_path
  attribute :style, &:published_style
  attribute :title, &:published_title
  attribute :masthead, &:published_masthead
  attribute :content, &:published_content
  attribute :byline, &:published_byline
  attribute :summary, &:published_summary
  attribute :excerpt, &:published_excerpt
  attribute :terms, &:published_terms
  attribute :date, &:published_at

  attribute :url  do |object|
    Rails.application.routes.url_helpers.published_collection_page_url(object)
  end

end
