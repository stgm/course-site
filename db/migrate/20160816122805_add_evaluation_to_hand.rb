class AddEvaluationToHand < ActiveRecord::Migration
  def change
    add_column :hands, :evaluation, :string
  end
end
