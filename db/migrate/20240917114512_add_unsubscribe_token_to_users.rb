class AddUnsubscribeTokenToUsers < ActiveRecord::Migration[7.0]
    def up
        add_column :users, :unsubscribe_token, :string

        User.reset_column_information
        User.find_each do |user|
            user.update_columns(unsubscribe_token: SecureRandom.hex(10))
        end
    end

    def down
        remove_column :users, :unsubscribe_token
    end
end
