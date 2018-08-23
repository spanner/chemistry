class PageAssets < ActiveRecord::Migration[5.2]
  def change
    add_column :chemistry_pages, :image_id, :integer
    add_column :chemistry_pages, :video_id, :integer
    rename_column :chemistry_pages, :began_at, :date
    rename_column :chemistry_pages, :ended_at, :to_date
  end
end
