require 'json'

module Chemistry
  class PagesController < ApplicationController
    include Chemistry::Concerns::Searchable

    load_and_authorize_resource except: [:published]


    # HTML routes
    #
    # public front page
    #
    def home
      @page = Page.home.first
      render template: "chemistry/pages/published"
    end

    # Editing front page
    #
    def editor
      render
    end

    # Any page, in its published form.
    #
    def published
      @path = params[:path] || ''
      @path = '/' if @path == ''
      if @page = Page.from_published_path(@path.strip).first
        render
      else
        page_not_found
      end
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
    # TODO eventually we will need a real Site object but for now this shortcut.
    # API will be preserved, more or less.
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

    def destroy
      @page.destroy
      head :no_content
    end


    ## Standard API responses

    def return_pages
      render json: PageSerializer.new(@pages).serialized_json
    end

    def return_page
      render json: PageSerializer.new(@page).serialized_json
    end

    def return_errors
      render json: { errors: @page.errors.to_a }, status: :unprocessable_entity
    end


    ## Error pages

    def page_not_found
      if @page = Page.from_published_path("/404").first
        render
      else
        render template: "pages/not_found"
      end
    end



    protected
  
    def create_page_params
      params.require(:page).permit(
        :template_id,
        :parent_id,
        :content,
        :keywords,
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
        :summary,
        :excerpt,
        :rendered_html,
        :keywords,
        :began_at,
        :ended_at,
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
          :background_html,
          :deleted_at
        ]
      )
    end


    ## Searchable configuration
    #
    def search_fields
      ['title^10', 'terms^5', 'content']
    end

    def search_highlights
      {tag: "<strong>"}
    end

    def search_default_sort
      "title"
    end

  end
end