class AssetOwners < ActiveRecord::Migration[5.2]
  def change
    add_column :chemistry_images, :user_id, :integer
    add_column :chemistry_videos, :user_id, :integer
    add_index :chemistry_images, :user_id
    add_index :chemistry_videos, :user_id

    add_column :chemistry_pages, :prefix, :string
  end
end
