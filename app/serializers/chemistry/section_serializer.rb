class Chemistry::SectionSerializer < ActiveModel::Serializer
  attributes :id,
             :page_id
             :position,
             :section_type_id,
             :section_type_slug,
             :title,
             :main,
             :aside,
             :image_id,
             :video_id,
             :document_id,
             :deleted_at

  def section_type_slug
    object.section_type.slug if object.section_type
  end
end
