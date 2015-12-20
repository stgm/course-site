class DefaultFromGrade < ActiveRecord::Migration
	def change
		change_column :grades, :mailed_at, :datetime, default: nil
	end
end
