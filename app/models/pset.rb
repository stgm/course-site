class Pset < ActiveRecord::Base

	belongs_to :page

	has_many :pset_files
	has_many :submits
	has_many :grades, through: :submits
	
	enum grade_type: [:integer, :float, :pass, :percentage]
	
	serialize :files, Hash
	serialize :config

	def all_filenames
		files.map { |h,f| f }.flatten.uniq
	end

	def submit_from(user)
		Submit.where(:user_id => user.id, :pset_id => id).first
	end

end
