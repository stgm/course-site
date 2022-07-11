class DropPsetFiles < ActiveRecord::Migration[6.1]
    def change
        drop_table :pset_files
    end
end
