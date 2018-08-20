require "fast_jsonapi"

class Chemistry::EnquirySerializer
  include FastJsonapi::ObjectSerializer

  set_type :enquiry

  attributes :id,
             :name,
             :email,
             :message,
             :closed

end
