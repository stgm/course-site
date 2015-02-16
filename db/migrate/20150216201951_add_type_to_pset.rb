class AddTypeToPset < ActiveRecord::Migration
	def change
		add_column :psets, :grade_type, :integer
	end
end
