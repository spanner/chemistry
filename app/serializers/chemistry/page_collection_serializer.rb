require "fast_jsonapi"

class Chemistry::PageCollectionSerializer
  include FastJsonapi::ObjectSerializer

  set_type :page_collection

  attributes :id,
             :title,
             :short_title,
             :slug,
             :introduction

end
