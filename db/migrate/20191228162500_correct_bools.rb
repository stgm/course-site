class CorrectBools < ActiveRecord::Migration[6.0]
	def change
		change_column :users, :active, :boolean, default: true
	end
end
