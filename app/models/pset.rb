class Pset < ActiveRecord::Base

	belongs_to :page
	has_many :pset_files
	has_many :submits
	attr_accessible :description, :name, :form, :message
	
	def submit_from(user)
		Submit.where(:user_id => user.id, :pset_id => id).first
	end

end
