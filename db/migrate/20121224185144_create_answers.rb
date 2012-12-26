class CreateAnswers < ActiveRecord::Migration
  def change
    create_table :answers do |t|
      t.references :user
      t.text :answer_data
      t.references :page

      t.timestamps
    end
    add_index :answers, :user_id
    add_index :answers, :page_id
  end
end
