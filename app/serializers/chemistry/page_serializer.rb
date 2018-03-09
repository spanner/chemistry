class Chemistry::PageSerializer
  include FastJsonapi::ObjectSerializer

  set_type :page

  attributes :id,
             :path,
             :slug,
             :parent_id,
             :type,
             :external_url,
             :template_id,
             :title,
             :summary,
             :excerpt,
             :home,
             :nav,
             :nav_name,
             :nav_position,
             :created_at,
             :updated_at,
             :published_at,
             :deleted_at

  has_many :sections
  has_many :documents
end
