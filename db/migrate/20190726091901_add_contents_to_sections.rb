class AddContentsToSections < ActiveRecord::Migration
  def change
    add_column :sections, :content_page, :text
    add_column :sections, :content_links, :text
  end
end
