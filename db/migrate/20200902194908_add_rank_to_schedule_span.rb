class AddRankToScheduleSpan < ActiveRecord::Migration[6.0]
  def change
    add_column :schedule_spans, :rank, :integer
  end
end
