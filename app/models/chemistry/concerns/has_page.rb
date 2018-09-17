module Chemistry::Concerns::HasPage
  extend ActiveSupport::Concern

  included do
    has_one :page, class_name: "Chemistry::Page", as: :owner
  end

  ## Interpolations
  # look like {key => string or proc}
  # If the key is found in page html as {{key}} or {{{key}}} then it is replaced with the string, or the return value of the proc.
  # Override this method to supply model-specific interpolations for inclusion in the page that this model owns.
  #
  def cms_interpolations
    {}
  end

  # The page slug is usually derived from its title, but you can override this method to supply a different base value.
  # The Chemistry page is provided in case you still want to include the title or some other page attribute.
  #
  def cms_slug_base(page)
    nil
  end

  ## Interpolation helpers
  #
  def render_partial(file)
    proc {
      ApplicationController.renderer.render(partial: file, object: self).html_safe
    }
  end

  def render_attribute(attribute_name)
    model = self
    proc {
      model.send(attribute_name.to_sym)
    }
  end

end