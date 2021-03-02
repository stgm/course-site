class Subpage < ApplicationRecord
    belongs_to :page
    default_scope { order(:position) }
end
