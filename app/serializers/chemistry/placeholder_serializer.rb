require "fast_jsonapi"

class Chemistry::PlaceholderSerializer
  include FastJsonapi::ObjectSerializer

  set_type :placeholder

  attributes :id,
             :template_id
             :position,
             :section_type_id,
             :section_type_slug,
             :title,
             :content,
             :aside,
             :created_at,
             :updated_at

end
