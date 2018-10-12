class Socialise < ActiveRecord::Migration[5.2]
  def change
    create_table :chemistry_socials, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.integer :page_id
      t.string :name
      t.string :url
      t.string :platform
      t.datetime :deleted_at
      t.timestamps
    end
  end
end
