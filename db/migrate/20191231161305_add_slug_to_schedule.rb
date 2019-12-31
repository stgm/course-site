class AddSlugToSchedule < ActiveRecord::Migration[6.0]
	def change
		add_column :schedules, :slug, :string
	    add_index :schedules, :slug, unique: true
		
		Schedule.all.each &:save
	end
end
