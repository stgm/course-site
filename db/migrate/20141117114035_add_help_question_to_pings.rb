class AddHelpQuestionToPings < ActiveRecord::Migration
	def change
		add_column :pings, :help_question, :text
	end
end
