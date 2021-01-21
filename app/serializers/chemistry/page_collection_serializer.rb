require "jsonapi/serializer"

class Chemistry::PageCollectionSerializer
  include JSONAPI::Serializer

  set_type :page_collection

  attributes :id,
             :title,
             :short_title,
             :slug,
             :introduction

end
