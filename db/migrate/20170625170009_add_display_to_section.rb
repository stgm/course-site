class AddDisplayToSection < ActiveRecord::Migration
	def change
		add_column :sections, :display, :boolean, default: false
	end
end
