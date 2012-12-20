class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.text :content
      t.text :orig_content
      t.references :comment_thread
      t.references :user

      t.timestamps
    end
  end
end
