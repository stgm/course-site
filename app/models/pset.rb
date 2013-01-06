class Pset < ActiveRecord::Base
	belongs_to :page
	has_many :pset_files
	attr_accessible :description, :name, :form
end
