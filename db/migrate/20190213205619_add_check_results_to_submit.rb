class AddCheckResultsToSubmit < ActiveRecord::Migration
	def change
		add_column :submits, :check_results, :text
		add_column :submits, :check_token, :string
	end
end
