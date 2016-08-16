class AddNoteToHand < ActiveRecord::Migration
  def change
    add_column :hands, :note, :text
  end
end
