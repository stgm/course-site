class ChangeBools < ActiveRecord::Migration[6.0]
	def up
		change_column :psets, :form, :boolean, :default => false
		change_column :psets, :url, :boolean, :default => false
		change_column :psets, :automatic, :boolean, :default => false
		change_column :psets, :test, :boolean, :default => false
		change_column :attendance_records, :local, :boolean, :default => false
		change_column :alerts, :published, :boolean, :default => false
		change_column :hands, :done, :boolean, :default => false
		change_column :hands, :success, :boolean, :default => false
		change_column :hands, :helpline, :boolean, :default => false
		change_column :pages, :public, :boolean, :default => false
		change_column :pings, :help, :boolean, :default => false
		change_column :pings, :active, :boolean, :default => false
		change_column :pset_files, :required, :boolean, :default => false
		change_column :schedules, :self_register, :boolean, :default => false
		change_column :schedules, :self_service, :boolean, :default => false
		change_column :sections, :display, :boolean, :default => false
		change_column :submits, :auto_graded, :boolean, :default => false
		change_column :users, :done, :boolean, :default => false
		change_column :users, :active, :boolean, :default => false
		change_column :users, :alarm, :boolean, :default => false
		
		puts "Don't forget to run  rails course:fixbools  to change bool columns in SQLite"
	end
end
