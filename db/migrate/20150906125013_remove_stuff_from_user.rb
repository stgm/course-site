class RemoveStuffFromUser < ActiveRecord::Migration
	def change
		remove_column :users, :schedule_id, :integer
		remove_column :users, :schedule_span_id, :integer
		remove_column :users, :avatar, :string
		remove_column :users, :uvanetid, :string
	end
end
