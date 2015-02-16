class Pset < ActiveRecord::Base

	belongs_to :page

	has_many :pset_files
	has_many :submits
	
	enum grade_type: [:integer, :float, :pass]

	attr_accessible :description, :name, :form, :message, :weight, :order
	
	def submit_from(user)
		Submit.where(:user_id => user.id, :pset_id => id).first
	end

end
