class ChemistryV2Init < ActiveRecord::Migration[6.0]
  def change

    rename_column :chemistry_pages, :content, :role
    rename_column :chemistry_pages, :rendered_html, :published_html
    add_column :chemistry_pages, :published_title, :text
    add_column :chemistry_pages, :published_byeline, :text
    add_column :chemistry_pages, :published_excerpt, :text
    add_column :chemistry_pages, :apparently_published_at, :datetime

    # will migrate from section html blocks
    add_column :chemistry_pages, :style, :string
    add_column :chemistry_pages, :content, :text, limit: 16.megabytes - 1
    add_column :chemistry_pages, :masthead, :text
    add_column :chemistry_pages, :byeline, :text
    add_column :chemistry_pages, :page_category_id, :integer
    add_column :chemistry_pages, :page_collection_id, :integer
    add_column :chemistry_pages, :terms, :text
    add_column :chemistry_pages, :featured_at, :datetime

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
