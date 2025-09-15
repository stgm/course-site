class AddAttemptsCountToSubmit < ActiveRecord::Migration[8.0]
    def change
        add_column :submits, :attempts_count, :integer, null: false, default: 0
    end
end
