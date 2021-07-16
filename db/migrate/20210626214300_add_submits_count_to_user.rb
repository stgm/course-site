class AddSubmitsCountToUser < ActiveRecord::Migration[6.1]
    def change
        add_column :users, :submits_count, :integer, null: false, default: 0

        reversible do |dir|
            dir.up { data }
        end
    end

    def data
        User.find_each do |u|
            User.reset_counters(u.id, :submits_count)
        end
    end
end
