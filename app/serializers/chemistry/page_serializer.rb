require "fast_jsonapi"

class Chemistry::PageSerializer
  include FastJsonapi::ObjectSerializer

  set_type :page

  attributes :id,
             :path,
             :slug,
             :style,
             :parent_id,
             :title,
             :masthead,
             :content,
             :byline,
             :summary,
             :excerpt,
             :terms,
             :home,
             :nav,
             :nav_name,
             :nav_position,
             :created_at,
             :updated_at,
             :published_at

  attribute :parent_id  { |object| object.parent } 
  attribute :page_category_id  { |object| object.page_category } 
  attribute :page_collection_id  { |object| object.page_collection } 

  attribute :url  do |object|
    Chemistry::Engine.routes.url_helpers.published_page_url(object.path, host: Chemistry.config.site_host)
  end

end
