require "fast_jsonapi"

class Chemistry::VideoSerializer
  include FastJsonapi::ObjectSerializer

  set_type :video

  attributes :id,
             :title,
             :caption,
             :file_name,
             :remote_url,
             :provider,
             :width,
             :height,
             :duration,
             :file_type,
             :file_size,
             :file_updated_at,
             :embed_code,
             :file_url,           # defaults to :full size
             :thumb_url,
             :half_url,
             :hero_url,
             :original_url,
             :mp4_url

end
