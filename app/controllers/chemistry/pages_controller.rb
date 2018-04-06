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
      render template: "chemistry/pages/published"
    end

    def editor
      render
    end

    def published
      @path = params[:path] || ''
      @path = '/' if @path == ''
      @page = Page.from_path(@path.strip).first
      head :not_found unless @page
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
        pages: PageSerializer.new(Page.all).serializable_hash,
        templates: TemplateSerializer.new(Template.all).serializable_hash,
        section_types: SectionTypeSerializer.new(SectionType.all).serializable_hash,
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
        @page.update_attributes published_at: Time.now
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

    def return_pages
      render json: PageSerializer.new(@pages).serialized_json
    end

    def return_page
      render json: PageSerializer.new(@page).serialized_json
    end

    def return_errors
      render json: { errors: @page.errors.to_a }, status: :unprocessable_entity
    end


    protected
  
    def create_page_params
      params.require(:page).permit(
        :template_id,
        :parent_id,
        :content,
        :external_url,
        :title
      )
    end

    def update_page_params
      params.require(:page).permit(
        :id,
        :slug,
        :home,
        :template_id,
        :parent_id,
        :content,
        :external_url,
        :document_id,
        :title,
        :nav,               # takes part in navigation?
        :nav_name,          # with this name
        :nav_position,      # in this position
        sections_data: [    # + nested section data
          :id,
          :section_type_id,
          :position,
          :title,
          :primary_html,
          :secondary_html,
          :section_type_id,
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