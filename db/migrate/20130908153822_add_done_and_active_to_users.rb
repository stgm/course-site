class AddDoneAndActiveToUsers < ActiveRecord::Migration
	def change
		add_column :users, :done, :boolean
		add_column :users, :active, :boolean
	end
end
