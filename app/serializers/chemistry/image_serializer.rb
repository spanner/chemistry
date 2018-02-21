class Chemistry::ImageSerializer < ActiveModel::Serializer
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
 
  def urls
    {
      original: object.file_url(:original),
      hero: object.file_url(:hero),
      full: object.file_url(:full),
      half: object.file_url(:half),
      thumb: object.file_url(:thumb)
    }
  end

end
