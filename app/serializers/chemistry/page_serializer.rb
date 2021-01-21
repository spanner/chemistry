require "jsonapi/serializer"

class Chemistry::PageSerializer
  include JSONAPI::Serializer

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

  attribute :url do |object|
    if object.home?
      Chemistry::Engine.routes.url_helpers.home_page_url(host: Chemistry.config.site_host)
    else
      Chemistry::Engine.routes.url_helpers.published_page_url(object.path, host: Chemistry.config.site_host)
    end
  end

end
