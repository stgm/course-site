class AddNotesToGrade < ActiveRecord::Migration
  def change
    add_column :grades, :notes, :text
  end
end
