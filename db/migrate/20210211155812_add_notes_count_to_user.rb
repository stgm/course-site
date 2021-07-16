class AddNotesCountToUser < ActiveRecord::Migration[6.1]
	def change
		add_column :users, :notes_count, :integer, null: false, default: 0

		reversible do |dir|
			dir.up { data }
		end
	end

	def data
		User.find_each do |u|
			u.update(notes_count: u.notes.where(log: false).count)
		end
	end
end
