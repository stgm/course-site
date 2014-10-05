class AddUrlToPsets < ActiveRecord::Migration
	def change
		add_column :psets, :url, :boolean
	end
end
