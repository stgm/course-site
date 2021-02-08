class AddStatusToUser < ActiveRecord::Migration[6.1]
	def up
		rename_column :users, :status, :status_description
		add_column :users, :status, :integer
		add_index :users, :status
		User.update_all(status: 'registered')
		User.includes(:submits).where.not(submits: { id: nil }).update_all(status: 'active')
		User.where(done:true).update_all(status: 'done')
		User.where(active:false).update_all(status: 'inactive')
	end
end
