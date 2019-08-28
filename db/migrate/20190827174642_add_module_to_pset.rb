class AddModuleToPset < ActiveRecord::Migration
	def change
		add_reference :psets, :mod, index: true, foreign_key: true
	end
end
