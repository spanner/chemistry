require "fast_jsonapi"

class Chemistry::ListedPageSerializer
  include FastJsonapi::ObjectSerializer

  set_type :page

  attributes :id,
             :path,
             :slug,
             :parent_id,
             :page_category_id,
             :page_collection_id,
             :title

end
