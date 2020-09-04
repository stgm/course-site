class AddPublicToScheduleSpans < ActiveRecord::Migration[6.0]
	def change
		add_column :schedule_spans, :public, :boolean, default: true
	end
end
