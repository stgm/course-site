class AddFormToPset < ActiveRecord::Migration
  def change
    add_column :psets, :form, :boolean
  end
end
