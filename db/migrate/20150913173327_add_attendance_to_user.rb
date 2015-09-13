class AddAttendanceToUser < ActiveRecord::Migration
  def change
    add_column :users, :attendance, :string
  end
end
