class Chemistry::PageSerializer < ActiveModel::Serializer
  attributes :id,
             :path,
             :slug,
             :parent_id,
             :template_id,
             :title,
             :summary,
             :home,
             :nav,
             :nav_name,
             :nav_position,
             :created_at,
             :updated_at,
             :published_at,
             :deleted_at

  has_many :sections, serializer: Chemistry::SectionSerializer
  has_many :documents, serializer: Chemistry::DocumentSerializer
end
