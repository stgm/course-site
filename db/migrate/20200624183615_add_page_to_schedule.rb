class AddPageToSchedule < ActiveRecord::Migration[6.0]
  def change
    add_reference :schedules, :page, null: true, foreign_key: true
  end
end
