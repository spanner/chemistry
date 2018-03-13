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
             :primary_html,
             :secondary_html,
             :created_at,
             :updated_at

end
