require 'json'

module Chemistry
  class PagesController < ApplicationController
    load_and_authorize_resource

    # HTML routes
    #
    # Only two: public front page and editing front page.
    #
    def home
      @page = Page.home.first
      render
    end

    def editor
      render
    end


    # API routes
    #
    # Support the editing UI and a few public functions like list pagination.
    #
    # `site` is an init package for the editing UI.
    #
    # Serialized collections do not include associates: the object must be fetched singly
    # to get eg. page sections or template placeholders.
    #
    def site
      render json: {
        pages: PageSerializer.new(Page.all),
        templates: TemplateSerializer.new(Template.all),
        section_types: SectionTypeSerializer.new(SectionType.all),
        locales: Chemistry.locale_urls
      }
    end

    def index
      return_pages
    end

    def show
      return_page
    end

    def create
      if @page.update_attributes(create_page_params)
        return_page
      else
        return_errors
      end
    end

    def update
      if @page.update_attributes(update_page_params)
        return_page
      else
        return_errors
      end
    end
  
    def publish
      if @page.update_attributes(publish_page_params)
        @page.publish!
        return_page
      else
        return_errors
      end
    end
  
    def destroy
      @page.destroy
      head :no_content
    end


    ## Standard responses

    def return_pages {
      render json: PageSerializer.new(@pages)
    }

    def return_page
      render json: PageSerializer.new(@page, include: [:sections, :documents])
    end

    def return_errors
      render json: { errors: @page.errors.to_a }, status: :unprocessable_entity
    end


    protected
  
    def create_page_params
      params.require(:page).permit(
        :template_id,
        :parent_id,
        :type,
        :external_url,
        :title
      )
    end

    def update_page_params
      params.require(:page).permit(
        :id,
        :template_id,
        :parent_id,
        :type,
        :external_url,
        :title,
        :nav,               # takes part in navigation?
        :nav_name,          # with this name
        :nav_position,      # in this position
        sections: [
          :id,
          :position,
          :title,
          :main,
          :aside,
          :section_type_id,
          :image_id,
          :video_id,
          :document_id,
          :deleted_at
        ]
      )
    end

    def publish_page_params
      params.permit(
        :rendered_html
      )
    end

  end
end