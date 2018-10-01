module Chemistry::Concerns::HasPage
  extend ActiveSupport::Concern

  class_methods do
    # `cms_base_path` gives us the branch of the page tree from which these object-attached pages should hang.
    # By default there is no value here, and all the object pages go in the base folder. For a simple list of items, that will be fine.
    # For a a more complex site you will want the list of refrigerators in /refrigerators and the current list of cheeses
    # in /cheeses/current.
    #
    # Note that this is an arbitrary value that does not necessarily create a page at the given path, or its parents
    # If a page should exist at the given path, its child pages will mingle with ours and receive the same validation-protection from path collisions.
    #
    attr_accessor :cms_path_base

    def has_one_page(opts={})
      has_one :page, class_name: "Chemistry::Page", as: :owner
      after_save :ensure_one_page
      if opts[:base].present?
        self.cms_path_base = opts[:base]
      end
    end

    def has_many_pages
      #TODO linking class that we might want to work :through
    end
   end


  ## Integration
  # The page slug is usually derived from its title, but you can override this method to supply a different base value.
  # The Chemistry page is provided in case you still want to include the title or some other page attribute.
  #
  def cms_slug_base(page)
    self.class.to_s
  end

  def cms_path_base
    self.class.cms_path_base || ""
  end

  def page_properties_given
    []
  end

  def page_properties_received
    []
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

  protected

  def ensure_one_page
    self.create_page unless self.page
  end

  def update_page
    # noop here
  end

end