class AddStatusToGrade < ActiveRecord::Migration
	def change
		add_column :grades, :status, :integer, null: false, default: 0
		Grade.where("done = 't'").update_all(status: 1)
		Grade.where("public = 't'").update_all(status: 2)
	end
end
