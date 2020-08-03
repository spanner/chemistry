require "fast_jsonapi"

class Chemistry::PublicPageSerializer
  include FastJsonapi::ObjectSerializer

  set_type :page

  attributes :id,
             :path,
             :slug,
             :parent_id,
             :published_title,
             :published_excerpt,
             :published_html,
             :terms,
             :style,
             :created_at,
             :updated_at,
             :published_at

end
