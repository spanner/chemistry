require "fast_jsonapi"

class Chemistry::PublicPageSerializer
  include FastJsonapi::ObjectSerializer

  set_type :page

  attributes :id,
             :path,
             :slug,
             :parent_id,
             :content,
             :external_url,
             :template_slug,
             :prefix,
             :title,
             :summary,
             :excerpt,
             :rendered_html,
             :keywords,
             :date,
             :to_date,
             :created_at,
             :updated_at,
             :published_at,
             :deleted_at

  has_many :socials
  belongs_to :image
  belongs_to :video


end
