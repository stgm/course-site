class AddMessageToPset < ActiveRecord::Migration
	def change
		add_column :psets, :message, :text
	end
end
