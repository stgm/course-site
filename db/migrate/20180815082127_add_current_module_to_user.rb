class AddCurrentModuleToUser < ActiveRecord::Migration
	def change
		add_reference :users, :current_module, index: true, foreign_key: true
	end
end
