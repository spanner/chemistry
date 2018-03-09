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

  has_many :placeholders

end
