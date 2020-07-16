require "fast_jsonapi"

class Chemistry::PageCategorySerializer
  include FastJsonapi::ObjectSerializer

  set_type :page_category

  attributes :id,
             :title,
             :slug,
             :introduction

end
