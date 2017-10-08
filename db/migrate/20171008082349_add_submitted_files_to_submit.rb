class AddSubmittedFilesToSubmit < ActiveRecord::Migration
  def change
    add_column :submits, :submitted_files, :text
  end
end
