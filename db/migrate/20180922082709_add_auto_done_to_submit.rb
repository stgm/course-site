class AddAutoDoneToSubmit < ActiveRecord::Migration
	def change
		add_column :submits, :auto_graded, :boolean, default: false, null: false
	end
end
