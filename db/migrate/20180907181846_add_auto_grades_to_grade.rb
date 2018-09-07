class AddAutoGradesToGrade < ActiveRecord::Migration
  def change
    add_column :grades, :auto_grades, :text
  end
end
