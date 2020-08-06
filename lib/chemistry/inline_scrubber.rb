module Chemistry
  class InlineScrubber < Rails::Html::PermitScrubber
    def initialize
      super
      self.tags = %w{em i strong b a}
      self.attributes = %w{href style}
    end
  end
end