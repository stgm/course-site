class DropComments < ActiveRecord::Migration
	def up
		drop_table :comment_threads
		drop_table :comments
	end

	def down
	end
end
