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
             :urls
 
end
