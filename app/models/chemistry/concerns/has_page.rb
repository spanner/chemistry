module Chemistry::Concerns::HasPage
  extend ActiveSupport::Concern

  class_methods do
    # `cms_base_path` gives us the branch of the page tree from which these object-attached pages should hang.
    # By default there is no value here, and all the object pages go in the base folder. For a simple list of items, that will be fine.
    # For a a more complex site you will want the list of refrigerators in /refrigerators and the current list of cheeses
    # in /cheeses/current.
    #
    # Specifying a cms path will create, where necessary, an 'anchor' page and above it a lineage of empty placeholder pages.
    #
    attr_accessor :cms_path_base, :cms_template_slug

    def has_one_page(opts={})
      has_one :page, class_name: "Chemistry::Page", as: :owner
      after_save :update_page
      if opts[:base].present?
        self.cms_path_base = opts[:base]
      end
      if opts[:template].present?
        self.cms_template_slug = opts[:template]
      end
    end

    def has_many_pages
      #TODO linking class that we might want to work :through
    end

    # cms_base_path can be string, proc or method name (as symbol)
    # so we only store it here, and will find or create pages at runtime.
    #
    def cms_path_base=(path)
      @cms_path_base = path
    end

    def anchor_page_path(owner)
      path = case @cms_path_base
      when String
        # we were given a path
        @cms_path_base
      when Proc
        # we were given a proc to call
        @cms_path_base.call(owner)
      when Symbol
        # we were given the name of a method to call on the owner object
        Rails.logger.warn "calling #{@cms_path_base.inspect} on #{owner.inspect}"
        owner.send @cms_path_base
      end
      path.sub(/^\//, '').sub(/\/$/, '')
    end

    def anchor_page_for(owner)
      if path = anchor_page_path(owner)
        Chemistry::Page.find_or_create_anchor_page(path)
      end
    end

    #TODO so we take different argument types here too?
    def page_template
      template_slug = @cms_template_slug.presence || self.to_s.underscore
      Chemistry::Template.find_by(slug: template_slug)
    end
  end


  def page?
    !!page
  end

  def page_id
    page.id if page
  end

  ## Integration
  # The page slug is usually derived from its title, but you can override this method to supply a different base value.
  # The Chemistry page is provided in case you still want to include the title or some other page attribute.
  #
  def cms_slug_base(page=nil)
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


  def properties_for_page
    {}
  end

  def properties_from_page
    {}
  end

  def init_page
    self.page || self.create_page(initial_page_properties)
  end

  def try_init_page
    init_page
  rescue => e
    debugger
  end

  def initial_page_properties
    properties_for_page.merge({
      parent: self.class.anchor_page_for(self),
      template: self.class.page_template
    })
  end

  protected

  def update_page
    if self.page
      self.page.update_attributes(properties_for_page)
    else
      init_page
    end
  end

  def update_from_page
    if self.page
      self.update_attributes(properties_from_page)
    end
  end

  def update_when_published
    self.touch
  end
end