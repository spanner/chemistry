class BackgroundHtml < ActiveRecord::Migration[5.2]
  def change
    add_column :chemistry_sections, :background_html, :text, limit: 16.megabytes - 1
  end
end
