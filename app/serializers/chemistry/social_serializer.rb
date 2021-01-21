require "jsonapi/serializer"

class Chemistry::SocialSerializer
  include JSONAPI::Serializer

  set_type :social

  attributes :id,
             :page_id,
             :position,
             :platform,
             :name,
             :url,
             :normalized_url,
             :app_url

end

