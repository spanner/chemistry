class SocialLinksController < ApplicationController
  layout false
  before_action :authenticate_user!
  load_resource :serial
  load_and_authorize_resource through: :serial

  # Return html fragment for inclusion as nested fieldset in serial form.
  def new
    # set defaults here if relevant
  end

end
