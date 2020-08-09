class ChemistryV2Init < ActiveRecord::Migration[6.0]
  def change

    rename_column :chemistry_pages, :content, :role
    rename_column :chemistry_pages, :rendered_html, :published_content

    add_column :chemistry_pages, :style, :string
    add_column :chemistry_pages, :content, :text, limit: 16.megabytes - 1
    add_column :chemistry_pages, :masthead, :text
    add_column :chemistry_pages, :byline, :text
    add_column :chemistry_pages, :page_category_id, :integer
    add_column :chemistry_pages, :page_collection_id, :integer
    add_column :chemistry_pages, :image_id, :integer
    add_column :chemistry_pages, :terms, :text
    add_column :chemistry_pages, :featured_at, :datetime

    add_column :chemistry_pages, :published_title, :text
    add_column :chemistry_pages, :published_byline, :text
    add_column :chemistry_pages, :published_excerpt, :text
    add_column :chemistry_pages, :published_slug, :string
    add_column :chemistry_pages, :published_path, :string
    add_column :chemistry_pages, :published_masthead, :text
    add_column :chemistry_pages, :published_style, :string
    add_column :chemistry_pages, :published_image_id, :integer
    add_column :chemistry_pages, :published_summary, :text
    add_column :chemistry_pages, :published_terms, :text
    add_column :chemistry_pages, :apparently_published_at, :datetime

    # ownership association is configurable
    add_column :chemistry_pages, :user_id, :string
    add_column :chemistry_images, :user_id, :string
    add_column :chemistry_videos, :user_id, :string
    add_column :chemistry_documents, :user_id, :string

    # optional filing
    create_table :chemistry_page_categories, id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
      t.string :title
      t.string :slug
      t.text :introduction
      t.timestamps
    end
    add_index :chemistry_page_categories, :slug

    create_table :chemistry_page_collections, id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.integer :position
      t.string :title
      t.string :short_title
      t.string :slug
      t.text :introduction
      t.boolean :featured, default: true
      t.boolean :private, default: false
      t.timestamps
    end
    add_index :chemistry_page_collections, [:slug, :private]

    # drop_table :chemistry_templates if table_exists? :templates
    # drop_table :chemistry_sections if table_exists? :sections
    # drop_table :chemistry_section_types if table_exists? :section_types
    # drop_table :chemistry_placeholders if table_exists? :placeholders
    # drop_table :chemistry_enquiries if table_exists? :enquiries
    # drop_table :chemistry_terms if table_exists? :chemistry_terms
    # drop_table :chemistry_page_terms if table_exists? :chemistry_page_terms
    # drop_table :chemistry_term_synonyms if table_exists? :chemistry_term_synonyms

  end
end
