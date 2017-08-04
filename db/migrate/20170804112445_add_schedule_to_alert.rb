class AddScheduleToAlert < ActiveRecord::Migration
  def change
    add_reference :alerts, :schedule, index: true, foreign_key: true
  end
end
