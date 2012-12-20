class CreateCommentThreads < ActiveRecord::Migration
  def change
    create_table :comment_threads do |t|
      t.string :title
      t.references :page

      t.timestamps
    end
  end
end
