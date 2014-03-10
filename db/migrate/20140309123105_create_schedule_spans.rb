class CreateScheduleSpans < ActiveRecord::Migration
	def change
		create_table :schedule_spans do |t|
			t.string :name
			t.references :schedule
			t.text :content

			t.timestamps
		end
		add_index :schedule_spans, :schedule_id
	end
end
