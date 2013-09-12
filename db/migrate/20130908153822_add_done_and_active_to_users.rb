class AddDoneAndActiveToUsers < ActiveRecord::Migration
	def change
		add_column :users, :done, :boolean, default: false
		add_column :users, :active, :boolean, default: true
	end
end
