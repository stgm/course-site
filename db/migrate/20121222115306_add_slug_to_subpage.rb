class AddSlugToSubpage < ActiveRecord::Migration
	def change
		add_column :subpages, :slug, :string
		add_index :subpages, :slug, unique: true
	end
end
