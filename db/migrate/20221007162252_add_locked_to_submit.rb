class AddLockedToSubmit < ActiveRecord::Migration[7.0]
    def change
        add_column :submits, :locked, :boolean, default: false, null: false
    end
end
