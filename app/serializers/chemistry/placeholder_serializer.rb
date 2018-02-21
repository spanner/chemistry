class Chemistry::PlaceholderSerializer < ActiveModel::Serializer
  attributes :id,
             :template_id
             :position,
             :section_type_id,
             :title,
             :content,
             :aside,
             :created_at,
             :updated_at
end
