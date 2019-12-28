class Grade < ApplicationRecord

	belongs_to :submit
	has_one :user, through: :submit
	delegate :name, to: :user, prefix: true, allow_nil: true
	has_one :pset, through: :submit
	delegate :name, to: :pset, prefix: true, allow_nil: true

	belongs_to :grader, class_name: "User"
	delegate :name, to: :grader, prefix: true, allow_nil: true
	delegate :initials, to: :grader, prefix: true, allow_nil: true

	before_save :set_calculated_grade, :unpublicize_if_undone # :update_grades_cache, 
	
	serialize :auto_grades
	
	# this is an OpenStruct to make sure that subgrades can be referenced as a method
	# for use in the grade calculation formulae in grading.yml
	serialize :subgrades, OpenStruct
	
	enum status: [:unfinished, :finished, :published, :discussed, :exported]
	
	# scope :published,  -> { where(status: Grade.statuses[:published]) }
	
	
	# this adds automatic grades to the subgrades quite aggressively
	after_initialize do
		if !self.persisted?
			# add any newly found autogrades to the subgrades as default
			self.submit.automatic().to_h.each do |k,v|
				self.subgrades[k] = v if not self.subgrades[k].present?
			end
		end
	end
	
	def reset_automatic_grades(auto_grades)
		auto_grades.to_h.each do |k,v|
			self.subgrades[k] = v
		end
	end
	
	def public?
		published? or discussed? or exported?
	end
	
	def to_partial_path
		# This very nice rails feature allows us to decide whether a form or
		# a read-only presentation should be rendered. Simply use "render
		# @grade_object" and this method will be consulted.
		unfinished? && 'grades/edit' || 'grades/show'
	end
	
	def last_graded
		updated_at && updated_at.to_formatted_s(:short) || "not yet"
	end
	
	def first_graded
		created_at && created_at.to_formatted_s(:short) || "not yet"
	end
	
	def auto_grades
		# provides default value
		super || {}
	end

	def subgrades=(val)
		# we would like this to be stored as an OpenStruct
		return super if val.is_a? OpenStruct

		# take this opportunity to convert any stringified stuff to numbers
		val.each do |k,v|
			# get type from grading config
			begin
				grade_type = Settings['grading']['grades'][self.pset_name]['subgrades'][k]
			rescue
				grade_type = "integer"
			end
			
			case grade_type
			when "integer", "boolean"
				val[k] = v.to_i unless v == ""
			when "float"
				val[k] = v.sub(",", ".").to_f unless v == ""
			end
		end if val

		super OpenStruct.new val.to_h if val
	end
	
	def grade
		g = read_attribute(:grade)
		return nil if !g
		g = (g/10.0).round(1)
		return g
	end
	
	def calculated_grade
		g = read_attribute(:calculated_grade)
		return nil if !g
		g = (g/10.0).round(1)
		return g
	end
	
	def any_final_grade
    # this function prefers hard-coded grades but can also provide the calculated grade
		self.grade or self.calculated_grade
	end

	def grade=(new_grade)
		if new_grade.blank? # erases the grade
			return super(nil)
		elsif new_grade.class == String
			new_grade.sub!(/,/,'.')
			case self.pset.grade_type
			when 'float'
				super(10.0 * new_grade.to_f)
			else # integer, pass
				super(10.0 * new_grade.to_i)
			end
		else
			case self.pset.grade_type
			when 'float'
				super(10.0 * new_grade.to_f)
			else # integer, pass
				super(10.0 * new_grade.to_i)
			end
		end
	end
	
	def set_calculated_grade
		if subgrades_changed?
			if calculated_grade = calculate_grade(self)
				case self.pset.grade_type
				when 'float'
					# calculated_grade = calculated_grade
				else # integer, pass
					calculated_grade = calculated_grade.round
				end
				self.calculated_grade = calculated_grade * 10
			else
				self.calculated_grade = nil
			end
		end
	end
	
	def calculate_grade(grade)
		f = Settings['grading']['grades'] if Settings['grading']
		return nil if f.nil?
		pset_name = grade.pset.name
		return nil if f[pset_name].nil? or f[pset_name]['calculation'].nil?
		begin
			cg = grade.subgrades.instance_eval(f[pset_name]['calculation'])
		rescue
			cg = nil
		end
		return cg
	end
	
	private
		
	def unpublicize_if_undone
		self.status = Grade.statuses[:unfinished] unless self.any_final_grade.present?
		true
	end
	
	def update_grades_cache
		user.update_grades_cache
	end

end
