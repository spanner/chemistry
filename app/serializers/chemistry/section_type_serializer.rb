class Chemistry::SectionTypeSerializer < ActiveModel::Serializer
  attributes :id,
             :title,
             :description,
             :icon_url,
             :image_urls

  def image_urls
    {
      original: object.image_url(:original),
      hero: object.image_url(:hero),
      full: object.image_url(:full),
      half: object.image_url(:half),
      thumb: object.image_url(:thumb)
    }
  end

end
