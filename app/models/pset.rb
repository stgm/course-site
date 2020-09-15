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
