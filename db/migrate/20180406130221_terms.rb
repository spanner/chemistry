class Terms < ActiveRecord::Migration[5.1]
  def change

    create_table :chemistry_terms do |t|
      t.string :term
      t.integer :parent_id
      t.timestamps
    end
    add_index :chemistry_terms, :term
    add_index :chemistry_terms, :parent_id

    create_table :chemistry_term_synonyms do |t|
      t.integer :term_id
      t.string :synonym
      t.timestamps
    end
    add_index :chemistry_term_synonyms, :term_id

    create_table :chemistry_page_terms do |t|
      t.integer :page_id
      t.integer :term_id
      t.timestamps
    end
    add_index :chemistry_page_terms, :page_id
    add_index :chemistry_page_terms, :term_id

  end
end
