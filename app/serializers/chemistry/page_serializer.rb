require "fast_jsonapi"

class Chemistry::PageSerializer
  include FastJsonapi::ObjectSerializer

  set_type :page

  attributes :id,
             :path,
             :slug,
             :style,
             :parent_id,
             :page_category_id,
             :page_collection_id,
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

  attribute :url  do |object|
    Chemistry::Engine.routes.url_helpers.published_collection_page_url(object.path, host: Settings.host)
  end

end
