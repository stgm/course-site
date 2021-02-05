class AddLogToNote < ActiveRecord::Migration[6.1]
	def change
		# add column, keeping all values nil for existing rows
		add_column :notes, :log, :boolean
		
		# change default value for new rows
		change_column_default :notes, :log, from: nil, to: false
	end
end
