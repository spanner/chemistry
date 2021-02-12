class PagePassword < ActiveRecord::Migration[6.1]
  def change

    add_column :chemistry_pages, :passworded, :boolean, default: false
    add_column :chemistry_pages, :password, :string
    add_column :chemistry_page_collections, :passworded, :boolean, default: false
    add_column :chemistry_page_collections, :password, :string

  end
end
