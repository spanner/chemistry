class Chemistry::SectionTypeSerializer
  include FastJsonapi::ObjectSerializer

  set_type :section_type

  attributes :id,
             :title,
             :description,
             :template,
             :icon_url,
             :image_urls

end
