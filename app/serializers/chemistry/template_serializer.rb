class Chemistry::TemplateSerializer < ActiveModel::Serializer
  attributes :id,
             :title,
             :description,
             :created_at,
             :updated_at

  has_many :placeholders, serializer: Chemistry::PlaceholderSerializer
end
