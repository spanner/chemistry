module Chemistry::Concerns::HasPage
  extend ActiveSupport::Concern

  class_methods do
    cattr_accessor :cms_page_collection

    def has_one_page(opts={})
      belongs_to :page, **opts.merge({class_name: "Chemistry::Page"})
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

  # Specify am attribute that provides the default page title,
  # Must be a database attribute or otherwise compatible with Dirty calls.
  #
  def page_default_title_attribute
    nil
  end

  # Specify am attribute that provides the default page content,
  # Must be a database attribute or otherwise compatible with Dirty calls.
  #
  def page_default_content_attribute
    nil
  end

  # Specify name of attachment from which default page image is taken.
  #
  def page_default_image_attachment
    nil
  end

  # Apply a transformation to the default content,
  # Default is to use `simple_format` to wrap paragraphs in P tags.
  # Should be simple and repeatable: we also use it when checking
  # whether previous default value is still in place and should be updated.
  #
  def prepare_default_content(text_content)
    return ActionView::Helpers::TextHelper.simple_format(text_content)
  end

  def init_page
    unless self.page
      page_properties = properties_for_page
      page_properties[:title] = send(page_default_title_attribute) if page_default_title_attribute
      page_properties[:content] = send(page_default_content_attribute) if page_default_content_attribute
      self.page = create_page(page_properties)
      if page_default_image_attachment && send(page_default_image_attachment).attached?
        attachment = send(page_default_image_attachment)
        page.pub_image = Chemistry::Image.new({
          io: attachment.service_url,
          filename: attachment.blob.filename
        })
        page.save
      end
      self.save
    end
  end

  def try_init_page
    init_page
  rescue => e
    debugger
  end


  protected

  def update_page
    if page
      update_properties = properties_for_page

      if page_default_title_attribute && saved_change_to_attribute(page_default_title_attribute)
        previous_default_title = send("#{page_default_title_attribute}_previously_was")
        if !page.title? || page.title == previous_default_title
          update_properties[:title] = send(page_default_title_attribute)
        end
      end

      if page_default_content_attribute && saved_change_to_attribute(page_default_content_attribute)
        previous_default_content = prepare_default_content(send("#{page_default_content_attribute}_previously_was"))
        if !page.content? || page.content == previous_default_content
          update_properties[:content] = prepare_default_content(send(page_default_content_attribute))
        end
      end

      page.update(update_properties)
    end
  end

  def update_from_page
    if page
      self.update(properties_from_page)
    end
  end

  def update_when_published
    self.touch
  end
end