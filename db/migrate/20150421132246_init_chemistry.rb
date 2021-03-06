# This migration comes from chemistry (originally 20150421132246)
class InitChemistry < ActiveRecord::Migration[5.1]
  def change
    create_table :chemistry_pages do |t|
      t.integer :template_id
      t.integer :parent_id
      t.string :path
      t.string :slug
      t.string :content, default: "page"
      t.string :title
      t.text :summary
      t.text :excerpt
      t.boolean :home, default: false
      t.boolean :nav, default: false
      t.string :nav_name
      t.integer :nav_position
      t.text :rendered_html, limit: 16.megabytes - 1
      t.string :external_url
      t.datetime :published_at
      t.datetime :deleted_at
      t.timestamps
    end
    add_index :chemistry_pages, [:published_at, :path]
    add_index :chemistry_pages, :parent_id
    add_index :chemistry_pages, :nav
    add_index :chemistry_pages, :home
    add_index :chemistry_pages, :deleted_at

    create_table :chemistry_images do |t|
      t.attachment :file
      t.string :remote_url
      t.string :title
      t.text :caption
      t.integer :width
      t.integer :height
      t.text :file_meta
      t.datetime :deleted_at
      t.timestamps
    end

    create_table :chemistry_videos do |t|
      t.attachment :file
      t.string :remote_url
      t.string :title
      t.text :caption
      t.string :provider
      t.text :embed_code
      t.integer :width
      t.integer :height
      t.integer :duration
      t.string :thumbnail_large
      t.string :thumbnail_medium
      t.string :thumbnail_small
      t.text :file_meta
      t.datetime :deleted_at
      t.timestamps
    end

    create_table :chemistry_documents do |t|
      t.attachment :file
      t.string :remote_url
      t.integer :position
      t.string :title
      t.text :caption
      t.text :file_meta
      t.datetime :deleted_at
      t.timestamps
    end

  end
end
