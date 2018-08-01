class AddGradesCacheToUser < ActiveRecord::Migration
	def change
		add_column :users, :grades_cache, :text
	end
end
