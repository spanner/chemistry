require "fast_jsonapi"

class Chemistry::SectionTypeSerializer
  include FastJsonapi::ObjectSerializer

  set_type :section_type

  attributes :id,
             :title,
             :description,
             :template

end
