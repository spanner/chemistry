require "fast_jsonapi"

class Chemistry::PageSerializer
  include FastJsonapi::ObjectSerializer

  set_type :page

  attributes :id,
             :path,
             :slug,
             :parent_id,
             :page_category_id,
             :page_collection_id,
             :title,
             :masthead,
             :content,
             :excerpt,
             :terms,
             :home,
             :nav,
             :nav_name,
             :nav_position,
             :created_at,
             :updated_at,
             :published_at,
             :deleted_at

end
