require "fast_jsonapi"

class Chemistry::SectionSerializer
  include FastJsonapi::ObjectSerializer

  set_type :section

  attributes :id,
             :page_id,
             :position,
             :section_type_id,
             :section_type_slug,
             :title,
             :primary_html,
             :secondary_html,
             :background_html,
             :deleted_at

end
