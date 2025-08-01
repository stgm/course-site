class AddBadSubmitEmailTrackingToUser < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :bad_submit_email_timestamps, :text
  end
end
