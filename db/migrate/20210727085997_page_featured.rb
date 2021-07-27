class PageFeatured < ActiveRecord::Migration[6.1]
  def change
    add_column :chemistry_pages, :featured_at, :datetime
  end
end
