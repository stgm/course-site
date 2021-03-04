class Pset < ApplicationRecord

	belongs_to :page, optional: true
	
	belongs_to :parent_pset, :class_name => 'Pset', optional: true
	has_many :child_psets, :class_name => 'Pset', :foreign_key => 'parent_pset_id'

	has_many :pset_files
	has_many :submits
	has_many :grades, through: :submits
	
	enum grade_type: [:integer, :float, :pass, :percentage]
	
	serialize :files, Hash
	serialize :config, Hash

	def self.ordered_by_grading

		psets = []

		# modules are an explicit grouping of multiple assignments and may be available in grading.yml
		if Settings['grading'] && Settings['grading']['modules']
			done_psets = []
			(Settings['grading']['modules'] || {}).each do |mod,psets|
				psets.each do |pset|
					done_psets << pset
				end
				done_psets << mod
			end
			psets += self.where(name: done_psets).sort_by{|m| done_psets.index(m.name)}
		end
		
		# in addition to the module assignments, we add any other assignments that are included in the final grade
		if Settings['grading'] && Settings['grading']['calculation']
			final_grades = Settings['grading']['calculation'].keys
			mods_in_final_grade = Settings['grading']['calculation'].values.map{|x| x.keys}.flatten.uniq
			psets_in_final_grade = mods_in_final_grade.map{|x| Settings['grading'][x]['submits']}.map{|y|y.keys}.flatten
			other_psets = self.where.not(id: psets).where(name: psets_in_final_grade + final_grades)
			psets += other_psets
		end
		
		# and then maybe grades that are mentioned in the grades section?
		if Settings['grading'] && Settings['grading']['grades']
			grades = Settings['grading']['grades'].keys
			graded_psets = self.where.not(id: psets).where(name: grades).order(:order)
			psets += graded_psets
		end

		# if there is nothing to work with from grading.yml, show all grades in order of availability
		if !Settings['grading'] || (!Settings['grading']['modules'] && !Settings['grading']['calculation'] && !Settings['grading']['grades'])
			psets = self.order(:order)
		end

		return psets

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

	def is_final_grade?
		self.name.in? Grading.final_grade_names
	end

end
