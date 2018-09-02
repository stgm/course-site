class AddFileContentsToSubmit < ActiveRecord::Migration
  def change
    add_column :submits, :file_contents, :text
  end
end
