class AddTodoToNotes < ActiveRecord::Migration[6.1]
	def change
		add_column :notes, :done, :boolean
		add_reference :notes, :assignee, null: true, foreign_key: { to_table: :users }
	end
end
