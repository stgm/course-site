class User < ApplicationRecord
	
	# normal users
	belongs_to :group, optional: true
	delegate :name, to: :group, prefix: true, allow_nil: true
	
	belongs_to :schedule, optional: true
	delegate :name, to: :schedule, prefix: true, allow_nil: true
	
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
	
	before_save :reset_group, if: :schedule_id_changed?
	before_save :reset_current_module, if: :schedule_id_changed?
	after_save :log_changes
	
	def accessible_schedules
		# ensure admins have access to all schedules at all times by overriding
		return Schedule.all if self.admin?
		self.schedules
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
			if login = Login.find_by_login(login)
				return login.user
			end
		end
	end
	
	def items(with_private=false)
		items = []
		items += submits.includes({:pset => [:parent_mod, :mod]}).where("submitted_at is not null").where("psets.mod_id is not null or mods_psets.pset_id is null").references(:psets, :mods).to_a
		items += grades.includes(:pset, :submit, :grader).showable.to_a
		items += hands.includes(:assist).to_a if with_private
		items += notes.includes(:author).to_a if with_private
		items = items.sort { |a,b| b.sortable_date <=> a.sortable_date }
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
					files["(#{submit.correctness_score}) #{submit.pset.name}/#{filename}"] = contents
				end
			end
		end
		return files
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
	
	def log_changes_for(user)
		@user = user
	end
	
	private
	
	def reset_group
		self.group_id = nil
	end
	
	def reset_current_module
		if span = self.schedule.schedule_spans.first
			self.current_module = span
		else
			self.current_module_id = nil
		end
	end
	
	def log_changes
		self.notes.create(text: self.previous_changes.reject{|k,v|k=='updated_at'}.collect{|k,v| "#{k}: #{v[1]}  "}.join, author_id: @user.id) if @user
	end
	
end
