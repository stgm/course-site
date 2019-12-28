class User < ApplicationRecord
	
	serialize :grades_cache
	
	# normal users
	belongs_to :group, optional: true
	belongs_to :schedule, optional: true
	belongs_to :current_module, class_name: "ScheduleSpan", optional: true
	
	# permissions for heads/tas
	has_and_belongs_to_many :groups
	has_and_belongs_to_many :schedules

	has_many :logins
	has_many :hands
	has_many :submits
	has_many :grades, through: :submits
	has_many :psets, through: :submits
	has_many :attendance_records
	has_many :notes, foreign_key: "student_id"
	has_many :authored_notes, class_name: "Note", foreign_key: "author_id"
	has_many :authored_grades, class_name: "Grade", foreign_key: "grader_id"
	
	has_one :ping

	scope :staff, -> { where(role: [User.roles[:admin], User.roles[:assistant], User.roles[:head]]) }
	scope :not_staff, -> { where.not(id: staff) }
	
	scope :not_inactive,    -> { where(active: true) }
	
	scope :active, -> { where('users.active != ? and users.done != ? and (users.started_at < ? or last_submitted_at is not null)', false, true, DateTime.now) }
	scope :registered, -> { where('users.last_submitted_at is null and (users.started_at is null or users.started_at > ?)', DateTime.now).where(active: true) }
	
	scope :inactive,  -> { where(active: false) }
	scope :done, -> { where(done:true) }
	scope :groupless,  -> { where(group_id: nil) }
	scope :but_not,   -> users { where("users.id not in (?)", users) }
	scope :with_login, -> login { joins(:logins).where("logins.login = ?", login)}
	scope :not_started, -> { where('started_at > ?', DateTime.now).where(last_submitted_at: nil) }
	scope :started, -> { where.not(last_submitted_at: nil) }
	scope :stagnated, -> { where("last_submitted_at < ?", 1.month.ago) }
	
	enum role: [:guest, :student, :assistant, :head, :admin]
	
	before_validation do
		# set user's current module to whatever's first in their newly assigned schedule
		if self.schedule_id_changed? || (self.schedule_id.present? && self.current_module_id.nil?)
			if span = self.schedule.schedule_spans.first
				self.current_module_id = span.id
			else
				self.current_module_id = nil
			end
		end
	end
	
	def check_current_module
		if self.schedule.present? && self.current_module.nil?
			if span = self.schedule.schedule_spans.first
				self.update(current_module_id: span.id)
			else
				self.update(current_module_id: nil)
			end
		end
	end
	
	def self.find_by_login(login)
		if login
			return Login.find_by_login(login).user
		end
	end
	
	def initials
		name.split.map(&:first).join
	end
	
	def suspect_name
		first, *rest = *name.split
		first + " " + rest.map(&:first).join()
	end
	
	def submit(pset)
		submits.where(:pset_id => pset.id).first
	end
	
	def activate
		update_attribute :active, true
	end
	
	def login_id
		return self.logins.first.login
	end

	def valid_profile?
		return !self.name.blank?
	end
	
	def can_submit?
		return self.valid_profile?
	end
	
	def staff?
		admin? or assistant? or head?
	end
	
	def senior?
		admin? or head?
	end
	
	def stagnated?
		if self.last_submitted_at.blank?
			self.started_at.present? && self.started_at < 1.month.ago
		else
			self.last_submitted_at < 1.month.ago
		end
	end
	
	def update_grades_cache
		grades = self.grades.select(:id, :submit_id, :pset_id, :grade, :calculated_grade)
		grouped = grades.group_by(&:pset_id).transform_values { |v| v[0].serializable_hash }
		update(grades_cache: grouped)
	end
	
	def update_last_submitted_at
		if last = submits.order("submitted_at").last
			update(last_submitted_at: last.submitted_at)
		end
	end

	def final_grade
		'N/A'
	end
	
	def all_submits
		self.grades.group_by { |i| i.submit.pset.name }.each_with_object({}) { |(k,v),o| o[k] = v[0] }
	end
	
	# retrieve all submitted file contents for all submits from a particular module (for this user)
	def files_for_module(mod)
		files = {}
		self.submits.where(pset: mod.psets).each do |submit|
			if submit.file_contents
				submit.file_contents.each do |filename, contents|
					files["(#{submit.check_score}) #{submit.pset.name}/#{filename}"] = contents
				end
			end
		end
		return files
	end
	
	def assign_final_grade(grader)
		logger.info "Trying to assign grade to user #{self.name}"
		
		# generate hash of { pset_name: submit_object }
		subs = self.all_submits
		tools = GradeTools.new
		
		# take all grading formulas in grading.yml and try to calculate
		Settings['grading']['calculation'].each do |name, formula|
			tools.log "- #{name}"
			grade = tools.calc_final_grade_formula(subs, formula)
			tools.log "    - result: #{grade}"
			if grade.present?
				final = self.submits.where(pset:Pset.where(name: name).first)
				# set grade either if there was already a grade or if sufficient or if insuff ok
				if final.count > 0 || grade.present?
					final = self.submits.where(pset:Pset.where(name: name).first).first_or_create
					final.create_grade if !final.grade
					# only change if grade hasn't been published yet
					if not ['published', 'exported'].include?(final.grade.status)
						final.grade.grade = grade
						if final.grade.grade_changed?
							logger.info "  changed to #{final.grade.grade}"
							final.grade.grader = grader
							final.grade.status = Grade.statuses['finished']
							final.grade.save
						end
					end
				end
			end
		end
		
		# logger.info tools.get_log
		return tools.get_log
	end
	
	def take_attendance
		symbols = "▁▂▃▄▅▆▇█"
		user_attendance = self.attendance_records.group_by_day(:cutoff, default_value: 0, range: 7.days.ago...Time.now).count.values
		graph = user_attendance.map { |v| symbols[[v,7].min] }.join("")
		self.update_attribute(:attendance, graph)
	end
	
	def generate_token!
		self.token = SecureRandom.hex(16)
		self.save
	end
	
	def generate_pairing_code!
		self.token = SecureRandom.random_number(10000)
		self.save
	end
	
end
