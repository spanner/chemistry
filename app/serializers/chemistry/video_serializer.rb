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
             :file_size,
             :file_type,
             :file_updated_at,
             :embed_code,
             :urls

end
