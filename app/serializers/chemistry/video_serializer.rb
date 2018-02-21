class Chemistry::VideoSerializer < ActiveModel::Serializer
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

  def urls
    {
      original: object.file_url(:original),
      full: object.file_url(:full),
      half: object.file_url(:half),
      thumb: object.file_url(:thumb)
    }
  end
  
  def title
    [object.provider, object.title.presence || object.file_file_name].compact.join(': ')
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
end
