class AddHelplineToHand < ActiveRecord::Migration
	def change
		add_column :hands, :helpline, :boolean
	end
end
