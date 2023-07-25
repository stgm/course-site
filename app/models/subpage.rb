class Subpage < ApplicationRecord
    belongs_to :page, touch: true
    default_scope { order(:position) }
end
