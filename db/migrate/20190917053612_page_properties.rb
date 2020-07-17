class PageProperties < ActiveRecord::Migration[5.2]
  def change

    add_column :chemistry_pages, :private, :boolean, default: false

  end
end
