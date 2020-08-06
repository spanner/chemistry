class PublicationV2 < ActiveRecord::Migration[6.0]
  def change
    add_column :chemistry_pages, :published_slug, :string
    add_column :chemistry_pages, :published_path, :string
    add_column :chemistry_pages, :published_masthead, :text
    add_column :chemistry_pages, :published_style, :string
    add_column :chemistry_pages, :published_summary, :text
    add_column :chemistry_pages, :published_terms, :text

    rename_column :chemistry_pages, :published_html, :published_content
    rename_column :chemistry_pages, :byeline, :byline
    rename_column :chemistry_pages, :published_byeline, :published_byline

    add_index :chemistry_pages, [:published_path, :published_at], name: "publication"
    add_index :chemistry_pages, :published_at
  end
end
