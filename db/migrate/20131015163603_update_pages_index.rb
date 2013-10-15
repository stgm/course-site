class UpdatePagesIndex < ActiveRecord::Migration
  def up
	  remove_index "pages", ["slug"]
	  add_index "pages", ["slug", "section_id"], unique: true
  end

  def down
  end
end
