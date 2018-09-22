class AddAutoToPset < ActiveRecord::Migration
	def change
		add_column :psets, :automatic, :boolean, default: false, null: false
		add_column :psets, :config, :text
	end
end
