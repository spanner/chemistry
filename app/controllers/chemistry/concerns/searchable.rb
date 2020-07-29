module Chemistry::Concerns::Searchable
  extend ActiveSupport::Concern

  included do
    before_action :init_pagination, only: [:index], if: :paginated?
    before_action :search_and_sort, only: [:index], if: :searchable?
  end

  protected

  def search_and_sort
    fields = search_fields
    aggregations = aggregated? ? search_aggregations : []
    @sort ||= params[:sort].presence || search_default_sort
    @order = params[:order].presence

    if params[:q].present?
      @q = params[:q]
      @sort = '_score'
      @order = :desc
      @searching = true
    else
      @q = "*"
      @sort = nil if @sort == '_score'
      @searching = false
    end

    @sort = search_default_sort unless search_permitted_sorts.include?(@sort)
    unless @sort == '_score'
      if sort_locale = params[:sortloc].presence
        @sort += ".#{sort_locale}"
      end
    end

    @order ||= @sort == "date" || @sort == 'created_at' ? :desc : :asc
    order = [{@sort => {order: @order}}]

    criteria = search_criterion_params.each_with_object({}) do |p, h|
      h[p] = params[p] if params[p].present?
      h[p] = true if h[p] == "true"
      h[p] = false if h[p] == "false"
    end

    options = {
      where: criteria,
      order: order
    }
    options.merge!({ per_page: @show, page: @page }) if paginated?
    options[:fields] = fields if fields.any?
    options[:aggs] = aggregations if aggregations.any?
    options[:match] = search_match if search_match
    options[:highlight] = search_highlights if search_highlights
    options[:includes] = search_includes if search_includes

    Rails.logger.warn "🕵️‍♂️ SEARCH OPTIONS: #{options.inspect}"

    klass = search_class
    search_results = klass.search @q, options
    instance_variable_set("@#{controller_name}", search_results)

    if paginated?
      @total = search_results.total_count
    end

    if aggregated?
      @aggs = search_results.aggs
    end
  end

  def search_class
    controller_path.classify.constantize
  end

  def search_fields
    []
  end

  def search_highlights
    false
  end

  def search_match
    nil
  end

  def search_aggregations
    []
  end

  def search_criterion_params
    []
  end

  def search_permitted_sorts
    ["_score", "name", "title", "created_at"]
  end

  def search_default_sort
    "name"
  end

  def search_includes
    []
  end

  def init_pagination
    @page = (params[:page].presence || 1).to_i
    @show = (params[:per_page].presence || default_per_page).to_i
  end

  def default_per_page
    10
  end

  def paginated?
    true
  end

  def searchable?
    true
  end

  def aggregated?
    true
  end
end