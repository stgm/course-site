class AddAlarmToUser < ActiveRecord::Migration
  def change
    add_column :users, :alarm, :boolean, null: false, default: false
  end
end
