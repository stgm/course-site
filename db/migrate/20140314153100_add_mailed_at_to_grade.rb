class AddMailedAtToGrade < ActiveRecord::Migration
	def change
		add_column :grades, :mailed_at, :datetime, null: false, default: DateTime.new
	end
end
