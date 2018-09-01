class AddFolderNameToSubmit < ActiveRecord::Migration
	def change
		add_column :submits, :folder_name, :string
	end
end
