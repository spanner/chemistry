module Chemistry::Concerns::HasPage
  extend ActiveSupport::Concern

  class_methods do
    cattr_accessor :cms_page_collection

    def has_one_page(opts={})
      belongs_to :page, opts.merge({class_name: "Chemistry::Page"})
      after_save :update_page
    end
  end

  def page?
    !!page
  end

  def page_id
    page.id if page
  end

  ## Interpolations
  # look like {key => string or proc}
  # If the key is found in page html as {{key}} or {{{key}}} then it is replaced with the string, or the return value of the proc.
  # Override this method to supply model-specific interpolations for inclusion in the page that this model owns.
  #
  def cms_interpolations
    {}
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


  def properties_for_page
    {}
  end

  def properties_from_page
    {}
  end

  def init_page
    self.page || self.create_page(properties_for_page)
  end

  def try_init_page
    init_page
  rescue => e
    debugger
  end


  protected

  def update_page
    if self.page
      self.page.update(properties_for_page)
    else
      init_page
    end
  end

  def update_from_page
    if self.page
      self.update(properties_from_page)
    end
  end

  def update_when_published
    self.touch
  end
end