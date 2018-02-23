class Chemistry::SectionSerializer < ActiveModel::Serializer
  attributes :id,
             :page_id
             :section_type_id,
             :position,
             :title,
             :main,
             :aside,
             :image_id,
             :video_id,
             :document_id,
             :deleted_at
end
