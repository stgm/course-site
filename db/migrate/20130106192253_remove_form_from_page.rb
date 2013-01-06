class RemoveFormFromPage < ActiveRecord::Migration
	def up
		remove_column :pages, :form
	end

	def down
		add_column :pages, :form, :boolean
	end
end
