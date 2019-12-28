class Pset < ApplicationRecord

	belongs_to :page, optional: true
	has_one :mod
	belongs_to :parent_mod, class_name: "Mod", foreign_key: "mod_id", optional: true
	# belongs_to :mod
	# has_one :parent_mod, class_name: "Mod"

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
