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
             :prefix,
             :title,
             :summary,
             :excerpt,
             :keywords,
             :date,
             :to_date,
             :home,
             :nav,
             :nav_name,
             :nav_position,
             :image_id,
             :video_id,
             :created_at,
             :updated_at,
             :published_at,
             :deleted_at,
             # and some signals for the UI
             :empty,
             :template_has_changed

end
