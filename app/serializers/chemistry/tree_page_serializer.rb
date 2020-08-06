require "fast_jsonapi"

class Chemistry::TreePageSerializer
  include FastJsonapi::ObjectSerializer

  set_type :page

  attributes :id,
             :path,
             :slug,
             :parent_id,
             :page_category_id,
             :page_collection_id,
             :title,
             :style,
             :created_at,
             :updated_at,
             :published_at

end
