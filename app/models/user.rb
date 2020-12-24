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
	scope :who_did_not_submit, ->(pset_id) { where("not exists (?)", Submit.where("submits.user_id = users.id").where(pset_id:pset_id)) }
	
	enum role: [:guest, :student, :assistant, :head, :admin]
	serialize :progress, Hash
	
	before_save :reset_group, if: :schedule_id_changed?
	before_save :reset_current_module, if: :schedule_id_changed?
	after_save :log_changes

	def create_profile(params, login)
		# cancel this thing if registration is not open (but not if first user)
		raise unless User.none? || Schedule.none? || Schedule.default

		self.assign_attributes(params)
		self.role = :student
		self.schedule ||= Schedule.default
		self.save!
	
		self.logins.create(login: login) unless self.logins.any?
	end

	def accessible_schedules
		if self.admin?
			# ensure admins have access to all schedules at all times by overriding
			Schedule.all
		else
			self.schedules
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
		# show all submits for psets that are _not_ a module
		items += submits.includes({:pset => [:parent_pset, :child_psets]}).where("submitted_at is not null").where("child_psets_psets.id is null or parent_psets_psets.id is not null").references(:parent_pset, :child_psets).to_a
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
		return self.persisted? && !self.name.blank?
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
	
	def hands_overview
		hands.where(success:true).map do |h|
			if h.closed_at.present? && h.claimed_at.present?
				[h.id, h.claimed_at, (h.closed_at - h.claimed_at)/60, h.assist_name || ""]
			end
		end.compact
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
	
	def reset_current_module
		if span = self.schedule.default_span(self.student?)
			self.current_module = span
		else
			self.current_module_id = nil
		end
	end

	private

	def reset_group
		self.group_id = nil
	end

	def log_changes
		changes = self.previous_changes.select{|k,v| ['current_module_id','status','current_schedule_id','alarm'].include?(k)}
		if changes.any?
			self.notes.create(text: changes.collect{|k,v| "#{k}: #{v[1]}  "}.join, author: Current.user)
		end
	end

end
