class PageAssets < ActiveRecord::Migration[5.2]
  def change
    add_column :chemistry_pages, :image_id, :integer
    add_column :chemistry_pages, :video_id, :integer
  end
end
