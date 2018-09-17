class Enquiries < ActiveRecord::Migration[5.2]
  def change
    create_table :chemistry_enquiries, options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.string   :name
      t.string   :email
      t.text     :message
      t.datetime :seen_at
      t.datetime :closed_at
      t.timestamps
    end

    add_index :chemistry_enquiries, :closed_at
  end
end
