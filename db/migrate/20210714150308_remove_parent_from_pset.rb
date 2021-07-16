class RemoveParentFromPset < ActiveRecord::Migration[6.1]
    def change
        remove_reference :psets, :parent_pset
    end
end
