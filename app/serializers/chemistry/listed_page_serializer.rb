require "jsonapi/serializer"

class Chemistry::ListedPageSerializer
  include JSONAPI::Serializer

  set_type :page

  attributes :id,
             :path,
             :slug,
             :parent_id,
             :page_category_id,
             :page_collection_id,
             :title

end
