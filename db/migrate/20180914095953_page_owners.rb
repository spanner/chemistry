class PageOwners < ActiveRecord::Migration[5.2]
  def change

    add_column :chemistry_pages, :owner_type, :string
    add_column :chemistry_pages, :owner_id, :integer
    add_index :chemistry_pages, [:owner_type, :owner_id]

  end
end
