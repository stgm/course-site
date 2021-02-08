class AddHandsCountToUser < ActiveRecord::Migration[6.1]
	def change
		add_column :users, :hands_count, :integer, default: 0, null: false
		add_column :users, :hands_duration_count, :integer, default: 0, null: false
		remove_column :users, :questions_count_cache
		User.find_each(batch_size: 100) do |u|
			u.update({
				hands_count: u.hands.where(success: true).count,
				hands_duration_count: u.hands.where(success: true).total_duration
			})
		end
	end
end
