class AddLocationConfirmedToUser < ActiveRecord::Migration[8.0]
    def change
        add_column :users, :location_confirmed, :boolean, default: false, null: false
    end
end
