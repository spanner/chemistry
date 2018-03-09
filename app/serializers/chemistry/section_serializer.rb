class Chemistry::SectionSerializer < ActiveModel::Serializer
  include FastJsonapi::ObjectSerializer

  set_type :section_type

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

end
