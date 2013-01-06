class Submit < ActiveRecord::Base
  belongs_to :user
  belongs_to :pset
  attr_accessible :submitted_at
end
