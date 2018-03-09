class Chemistry::DocumentSerializer
  include FastJsonapi::ObjectSerializer

  set_type :document

  attributes :id,
             :page_id,
             :title,
             :caption,
             :file_name,
             :file_file_size,
             :file_content_type,
             :file_updated_at,
             :file_url,
             :remote_url
 
end
