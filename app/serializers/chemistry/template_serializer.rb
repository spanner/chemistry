require "fast_jsonapi"

class Chemistry::TemplateSerializer
  include FastJsonapi::ObjectSerializer

  set_type :template

  attributes :id,
             :title,
             :slug,
             :position,
             :description,
             :created_at,
             :updated_at

end
