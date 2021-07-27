require "jsonapi/serializer"

class Chemistry::TreePageSerializer
  include JSONAPI::Serializer

  set_type :page

  attributes :id,
             :path,
             :slug,
             :parent_id,
             :page_category_id,
             :page_collection_id,
             :thumbnail_url,
             :image_url,
             :title,
             :style,
             :excerpt,
             :created_at,
             :updated_at,
             :published_at

end
