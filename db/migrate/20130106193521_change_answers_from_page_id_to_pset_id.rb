class ChangeAnswersFromPageIdToPsetId < ActiveRecord::Migration
	def up
		add_column :answers, :pset_id, :integer
		remove_column :answers, :page_id
	end

	def down
		add_column :answers, :page_id, :integer
		remove_column :answers, :pset_id
	end
end
