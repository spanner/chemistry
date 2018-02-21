class Chemistry::SectionSerializer < ActiveModel::Serializer
  attributes :id,
             :page_id
             :position,
             :section_type_id,
             :title,
             :content,
             :aside,
             :image_id,
             :video_id,
             :document_id,
             :deleted_at
end
