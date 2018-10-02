require "fast_jsonapi"

class Chemistry::PageSerializer
  include FastJsonapi::ObjectSerializer

  set_type :page

  attributes :id,
             :path,
             :slug,
             :parent_id,
             :content,
             :external_url,
             :template_id,
             :title,
             :summary,
             :excerpt,
             :keywords,
             :date,
             :to_date,
             :home,
             :anchor,
             :nav,
             :nav_name,
             :nav_position,
             :image_id,
             :video_id,
             :created_at,
             :updated_at,
             :published_at,
             :deleted_at


end
