class AddLastSubmittedAtToUser < ActiveRecord::Migration
	def change
		add_column :users, :last_submitted_at, :datetime
	end
end
