class AddFinalToPset < ActiveRecord::Migration[7.0]
    def change
        add_column :psets, :final, :boolean, default: false
    end
end
