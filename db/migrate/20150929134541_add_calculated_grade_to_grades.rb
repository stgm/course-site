class AddCalculatedGradeToGrades < ActiveRecord::Migration
	def change
		add_column :grades, :calculated_grade, :integer
	end
end
