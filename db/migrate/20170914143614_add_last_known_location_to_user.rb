class AddLastKnownLocationToUser < ActiveRecord::Migration
	def change
		add_column :users, :last_known_location, :string
	end
end
