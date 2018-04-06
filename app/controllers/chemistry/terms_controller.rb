module Chemistry
  class TermsController < ApplicationController
    include Chemistry::Concerns::Searchable

    def index
      render json: TermSerializer.new(@terms).serialized_json
    end

    def show
      if @term = Term.where(term: params[:id]).includes(:pages).limit(1).first()
        render json: TermSerializer.new(@terms).serialized_json
      else
        raise ActiveRecord::RecordNotFound
      end
    end

    protected

    ## Searchable configuration
    #
    def search_fields
      ["term^5", "synonyms"]
    end

    def search_default_sort
      "term"
    end

    def search_match
      :word_start
    end

  end
end