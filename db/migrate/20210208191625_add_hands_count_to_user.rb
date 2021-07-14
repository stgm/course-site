class AddHandsCountToUser < ActiveRecord::Migration[6.1]
	def change
		remove_column :users, :questions_count_cache, :integer, default: 0, null: false

		add_column    :users, :hands_count,           :integer, default: 0, null: false
		add_column    :users, :hands_duration_count,  :integer, default: 0, null: false

		reversible do |dir|
			dir.up { data }
		end
	end

	def data
		User.find_each do |u|
			u.hands_count = u.hands.where(success: true).count
			u.hands_duration_count = u.hands.where(success: true).total_duration
			u.save!
		end
	end
end
