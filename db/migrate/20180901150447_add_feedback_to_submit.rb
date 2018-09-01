class AddFeedbackToSubmit < ActiveRecord::Migration
	def change
		add_column :submits, :check_feedback, :text
		add_column :submits, :style_feedback, :text
	end
end
