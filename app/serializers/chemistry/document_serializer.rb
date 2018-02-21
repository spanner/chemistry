class Chemistry::DocumentSerializer < ActiveModel::Serializer
  attributes :id,
             :page_id,
             :title,
             :caption,
             :file_name,
             :file_size,
             :file_type,
             :file_updated_at,
             :url,
             :remote_url
 
  def title
    object.title.presence || object.file_file_name
  end

  def file_name
    object.file_file_name
  end

  def file_type
    object.file_content_type
  end

  def file_size
    object.file_file_size
  end
 
  def url
    object.file_url(:original)
  end

end
