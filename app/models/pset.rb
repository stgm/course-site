class Pset < ApplicationRecord

	belongs_to :page, optional: true
	has_one :mod
	belongs_to :parent_mod, class_name: "Mod", foreign_key: "mod_id", optional: true
	delegate :pset, to: :parent_mod, prefix: 'parent', allow_nil: true
	# belongs_to :mod
	# has_one :parent_mod, class_name: "Mod"

	has_many :pset_files
	has_many :submits
	has_many :grades, through: :submits
	
	enum grade_type: [:integer, :float, :pass, :percentage]
	
	serialize :files, Hash
	serialize :config

	def self.ordered_by_grading
		if Settings['grading'] && Settings['grading']['modules']
			done_psets = []
			(Settings['grading']['modules'] || {}).each do |mod,psets|
				psets.each do |pset|
					done_psets << pset
				end
				done_psets << mod
			end
			psets = self.where(name: done_psets).sort_by{|m| done_psets.index(m.name)}
			
			if Settings['grading']['calculation']
				mods_in_final_grade = Settings['grading']['calculation'].values.map{|x| x.keys}.flatten
				psets_in_final_grade = mods_in_final_grade.map{|x| Settings['grading'][x]['submits']}.map{|y|y.keys}.flatten
				other_psets = self.where.not(id: psets).where(name: psets_in_final_grade).order(:order)
				puts other_psets
				psets += other_psets
			end
			
			return psets
		else
			psets = self.order(:order)
		end
	end

	def all_filenames
		files.map { |h,f| f }.flatten.uniq
	end

	def submit_from(user)
		Submit.where(:user_id => user.id, :pset_id => id).first
	end
	
	def check_config
		config && config['check']
	end

end
