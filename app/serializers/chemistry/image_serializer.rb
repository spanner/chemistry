require "fast_jsonapi"

class Chemistry::ImageSerializer
  include FastJsonapi::ObjectSerializer

  set_type :image

  attributes :id,
             :title,
             :caption,
             :file_name,
             :remote_url,
             :width,
             :height,
             :file_size,
             :file_type,
             :file_updated_at,
             :file_url,           # defaults to :full size
             :thumb_url,
             :half_url,
             :hero_url,
             :original_url
 
end
