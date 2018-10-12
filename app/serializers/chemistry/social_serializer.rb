require "fast_jsonapi"

class Chemistry::SocialSerializer
  include FastJsonapi::ObjectSerializer

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

