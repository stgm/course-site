class AddSeatToSubmits < ActiveRecord::Migration[8.0]
    def change
        add_column :submits, :seat, :string

        # One student per table: the exam is identified by the pset, so a seat is
        # unique within it. Partial, because unplaced students all have NULL.
        add_index :submits, [ :pset_id, :seat ], unique: true, where: "seat IS NOT NULL"
    end
end
