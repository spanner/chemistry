require "jsonapi/serializer"

class Chemistry::PageCategorySerializer
  include JSONAPI::Serializer

  set_type :page_category

  attributes :id,
             :title,
             :slug,
             :introduction

end
