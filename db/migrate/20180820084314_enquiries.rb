class Enquiries < ActiveRecord::Migration[5.2]
  def change
    create_table :chemistry_enquiries, options: 'ENGINE=InnoDB DEFAULT CHARSET=utf8' do |t|
      t.string   :name,
      t.string   :email,
      t.text     :message,
      t.boolean  :closed, default: false
      t.timestamps
    end

    add_index :droom_enquiries, :closed
  end
end
