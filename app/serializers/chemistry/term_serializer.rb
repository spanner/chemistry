require "fast_jsonapi"

class Chemistry::TermSerializer
  include FastJsonapi::ObjectSerializer

  set_type :term

  attributes :id,
             :term,
             :synonyms

end
