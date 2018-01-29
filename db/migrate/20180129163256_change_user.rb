class ChangeUser < ActiveRecord::Migration
  def up
	  # this column is sometimes empty but should in that case be processable as a string
	  change_column_default(:users, :attendance, "")
	  change_column_null(:users, :attendance, false, "")
  end
end
