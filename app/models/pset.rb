class Pset < ActiveRecord::Base

	belongs_to :page

	has_many :pset_files
	has_many :submits
	has_many :grades, through: :submits
	
	enum grade_type: [:integer, :float, :pass, :percentage]
	
	serialize :files, Hash

	# def files=(val)
	# 	# we would like this to be stored as an OpenStruct
	# 	return super val if val.is_a? OpenStruct
	#
	# 	super OpenStruct.new val.to_h if val
	# end

	def submit_from(user)
		Submit.where(:user_id => user.id, :pset_id => id).first
	end

end
