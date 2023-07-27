class AddPublishAtToScheduleSpan < ActiveRecord::Migration[7.0]
    def change
        add_column :schedule_spans, :publish_at, :datetime
    end
end
