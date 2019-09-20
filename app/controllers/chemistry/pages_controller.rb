require 'json'

module Chemistry
  class PagesController < Chemistry::ApplicationController
    include Chemistry::Concerns::Searchable

    # specially-named page routes make it easier to skip authentication
    load_and_authorize_resource except: [:published, :latest, :children, :home, :bundle, :new]


    # HTML routes
    #
    # Public front page
    #
    def home
      if @page = Chemistry::Page.home.first
        render template: "chemistry/pages/published", layout: Chemistry.public_layout
      else
        render template: "chemistry/welcome", layout: "chemistry/application"
      end
    end

    # Any page in its published form.
    #
    def published
      @path = params[:id] || ''
      @path.sub /\/$/, ''
      @path.sub /^\//, ''
      @page = Chemistry::Page.published.with_path(@path.strip).first
      if @page && (@page.public? || user_signed_in?)
        render layout: Chemistry.public_layout
      else
        page_not_found
      end
    end

    def controls
      if params[:path].present?
        @page = Chemistry::Page.find_by(path: params[:path])
      end
      if @page && can?(:edit, @page)
        render layout: false
      else
        head :no_content
      end
    end

    # Welcome to empty site
    #
    def welcome
      render template: "chemistry/welcome", layout: "chemistry/application"
    end

    # Editing front page is an index view
    #
    def editor
      render
    end

    # New and edit are shortcuts to views within the SPA editor.
    #
    def new
      @page = Chemistry::Page.new(new_page_params)
      render template: "chemistry/pages/editor"
    end

    def edit
      if @page
        render template: "chemistry/pages/editor"
      else
        raise ActiveRecord::RecordNotFound
      end
    end


    ## API routes
    #
    # Support the editing UI and a few public functions like list pagination.
    #
    def index
      return_pages
    end

    def show
      return_page if stale?(etag: @page, last_modified: @page.published_at, public: true)
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
        @page.touch
        return_page
      else
        return_errors
      end
    end

    def destroy
      @page.destroy
      head :no_content
    end

    # `site` is an init package for the editing UI.
    #
    # Serialized collections do not include associates: the object must be fetched singly
    # to get eg. page sections or template placeholders.
    #
    # TODO soon we will need a real Site object but for now, this bundle.
    # API will be preserved, more or less.
    #
    def site
      if current_user.respond_to?(:can?) && current_user.can?(:manage, Chemistry::Page)
        @pages = Page.all
        @templates = Template.all
        @section_types = SectionType.all
      elsif current_user.respond_to?(:pages)
        @pages = current_user.pages.includes(:template, sections: [:section_type])
        @templates = @pages.map(&:template).compact.uniq
        @section_types = @pages.map(&:sections).flatten.map(&:section_type).flatten.compact.uniq
      end
      render json: {
        pages: PageSerializer.new(@pages).serializable_hash,
        templates: TemplateSerializer.new(@templates).serializable_hash,
        section_types: SectionTypeSerializer.new(@section_types).serializable_hash,
        locales: Chemistry.locale_urls
      }
    end

    # `bundle` is a package of all published pages suitable for presentation in eg. an app.
    # etag / cache metadata very important because while the package not expensive to build,
    # it is bulky and likely to be delivered over mobile data.
    # TODO soon to be another view of the Site object.
    #
    def bundle
      if latest_page = Page.published_and_placeholders.latest.limit(1).first
        expires_in(1.hour, public: true)
        if stale?(etag: latest_page, last_modified: latest_page.published_at, public: true)
          @pages = Page.published_and_placeholders.includes(:sections, :socials, :image, :video)
          return_pages_with_everything
        end
      end
    end

    # `latest` returns a list useful for populating sidebars and menus with 'latest update' type blocks
    # optional `parent` param contains a path string, scopes the list to children of the page at that path.
    #
    def latest
      limit = params[:limit].presence || 1
      @pages = Page.published.latest.limit(limit)
      if params[:parent] and @page = Page.where(path: params[:parent]).first
        @pages = @pages.with_parent(@page)
      end
      render layout: false
    end

    # `children` returns paginated lists of published pages under the given page path.
    # TODO: search index!
    #
    def children
      if @page = Page.where(path: params[:parent]).first
        @pages = @page.child_pages.published

        # sort
        @sort = params[:sort] if ["published_at", "date", "title"].include?(params[:sort])
        @sort ||= "published_at"
        @order = params[:order] || (@sort == 'title' ? "asc" : "desc")
        Rails.logger.warn "children: sort #{@sort}, order #{@order}: #{{@sort => @order}.inspect}"
        @pages = @pages.order(@sort => @order)

        # paginate
        @p = params[:p] || 1
        @pp = params[:limit] || Chemistry.default_per_page
        @pages = @pages.page(@p).per(@pp)
        render layout: false
      else
        head :no_content
      end
    end


    ## Standard API responses

    def return_pages
      render json: PageSerializer.new(@pages).serialized_json
    end

    def return_pages_with_everything
      render json: PublicPageSerializer.new(@pages, include: [:sections, :socials, :image, :video]).serialized_json
    end

    def return_page
      render json: PageSerializer.new(@page).serialized_json
    end

    def return_errors
      render json: { errors: @page.errors.to_a }, status: :unprocessable_entity
    end


    ## Error pages

    def page_not_found
      if @page = Page.published.with_path("/404").first
        render layout: Chemistry.public_layout
      else
        render template: "chemistry/pages/not_found", layout: Chemistry.public_layout
      end
    end


    protected
  
    ## Permitted parameters
    #
    # New-page link can set basic properties
    #
    def new_page_params
      params.permit(
        :path,
        :private,
        :title
      )
    end
  
    # Page creation is a preparatory ste
    # to make our associations a bit easier to manage.
    #
    def create_page_params
      params.require(:page).permit(
        :slug,
        :template_id,
        :parent_id,
        :content,
        :keywords,
        :external_url,
        :private,
        :title
      )
    end

    def update_page_params
      params.require(:page).permit(
        :id,
        :slug,
        :private,
        :home,
        :template_id,
        :parent_id,
        :content,
        :external_url,
        :document_id,
        :prefix,
        :title,
        :summary,
        :excerpt,
        :rendered_html,
        :image_id,
        :video_id,
        :nav,               # takes part in navigation?
        :nav_name,          # with this name
        :nav_position,      # in this position
        :keywords,
        :date,
        :to_date,
        socials_data: [    # + nested socials data
          :position,
          :platform,
          :name,
          :reference,
          :url
        ],
        sections_data: [    # + nested section data
          :id,
          :section_type_id,
          :position,
          :prefix,
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