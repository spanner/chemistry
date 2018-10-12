require "fast_jsonapi"

class Chemistry::SocialSerializer
  include FastJsonapi::ObjectSerializer

  set_type :social

  attributes :id,
             :serial_id,
             :platform,
             :name,
             :url,
             :normalized_url,
             :app_url

end

