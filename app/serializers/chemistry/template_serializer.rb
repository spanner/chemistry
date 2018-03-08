class Chemistry::TemplateSerializer < ActiveModel::Serializer
  attributes :id,
             :title,
             :slug,
             :position,
             :description,
             :created_at,
             :updated_at

  has_many :placeholders, serializer: Chemistry::PlaceholderSerializer
end
