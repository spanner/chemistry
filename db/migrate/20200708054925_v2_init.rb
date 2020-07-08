class V2Init < ActiveRecord::Migration[6.0]
  def change

    rename_column :chemistry_pages, :content, :role
    
    # will migrate from section html blocks
    add_column :chemistry_pages, :content, :text, limit: 16.megabytes - 1
    add_column :chemistry_pages, :masthead, :text

    create_table :chemistry_page_categories, id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
      t.string :title
      t.string :slug
      t.timestamps
    end
    add_index :chemistry_page_categories, :slug

    create_table :chemistry_page_collections, id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.string :title
      t.string :short_title
      t.string :slug
      t.integer :image_id
      t.text :content
      t.text :cobrand
      t.integer :position
      t.boolean :public, default: false
      t.timestamps
    end
    add_index :chemistry_page_collections, :slug

    drop_table :chemistry_templates if table_exists? :templates
    drop_table :chemistry_sections if table_exists? :sections
    drop_table :chemistry_section_types if table_exists? :section_types
    drop_table :chemistry_placeholders if table_exists? :placeholders
    drop_table :chemistry_enquiries if table_exists? :enquiries

  end
end
