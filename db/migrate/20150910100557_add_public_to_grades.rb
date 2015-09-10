class AddPublicToGrades < ActiveRecord::Migration
	def change
		add_column :grades, :done, :boolean, default: false
		add_column :grades, :public, :boolean, default: false
	end
end
