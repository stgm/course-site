class Mod < ApplicationRecord

	has_many :psets # that belong to the module
	belongs_to :pset # to assign grades for this module

end
