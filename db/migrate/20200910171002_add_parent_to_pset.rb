class AddParentToPset < ActiveRecord::Migration[6.0]
	def change
		add_reference :psets, :parent_pset
	end
end
