class AddMonitoringConsentToUser < ActiveRecord::Migration
	def change
		add_column :users, :monitoring_consent, :boolean, default: false
	end
end
