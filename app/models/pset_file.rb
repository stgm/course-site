class PsetFile < ActiveRecord::Base
	belongs_to :pset
	attr_accessible :filename, :required
end
