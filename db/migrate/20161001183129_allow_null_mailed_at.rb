class AllowNullMailedAt < ActiveRecord::Migration
  def change
	  change_column :grades, :mailed_at, :datetime, :null => true
  end
end
