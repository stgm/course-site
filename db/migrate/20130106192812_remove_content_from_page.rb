class RemoveContentFromPage < ActiveRecord::Migration
	def up
		remove_column :pages, :content
		remove_column :sections, :content
	end

	def down
		add_column :pages, :content, :string
		add_column :sections, :content, :string
	end
end
