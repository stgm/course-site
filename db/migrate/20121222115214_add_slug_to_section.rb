class AddSlugToSection < ActiveRecord::Migration
	def change
		add_column :sections, :slug, :string
		add_index :sections, :slug, :unique => true
	end
end
