class AddFormToPage < ActiveRecord::Migration
  def change
    add_column :pages, :form, :boolean
  end
end
