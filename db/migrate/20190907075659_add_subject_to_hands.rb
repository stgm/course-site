class AddSubjectToHands < ActiveRecord::Migration
  def change
    add_column :hands, :subject, :string
  end
end
