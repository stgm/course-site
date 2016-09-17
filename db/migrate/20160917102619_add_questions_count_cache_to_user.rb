class AddQuestionsCountCacheToUser < ActiveRecord::Migration
	def change
		add_column :users, :questions_count_cache, :integer, null: false, default: 0
		User.all.each do |u|
			u.update_attribute(:questions_count_cache, u.hands.count)
		end
	end
end
