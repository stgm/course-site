class AddDatesToHands < ActiveRecord::Migration
	def change
		add_column :hands, :claimed_at, :datetime
		add_column :hands, :closed_at, :datetime
	end
end
