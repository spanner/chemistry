module Chemistry
  class ContentScrubber < Rails::Html::PermitScrubber
    def initialize
      super
      self.tags = %w{div figure img figcaption h2 h3 p ul ol li blockquote em i strong b a iframe}
      self.attributes = %w{href rel src class style allowfullscreen frameborder}
    end
  end
end