class User < ActiveRecord::Base
	
	belongs_to :group
	belongs_to :schedule

	has_many :logins
	has_many :hands
	has_many :submits
	has_many :grades, through: :submits
	has_many :psets, through: :submits
	has_many :attendance_records
	
	has_one :ping

	scope :staff, -> { where(role: [User.roles[:admin], User.roles[:assistant], User.roles[:head]]) }
	scope :not_staff, -> { where.not(id: staff) }
	scope :active,    -> { where(active: true) }
	scope :inactive,  -> { where(active: false) }
	scope :no_group,  -> { where(group_id: nil) }
	scope :but_not,   -> users { where("users.id not in (?)", users) }
	scope :with_login, -> login { joins(:logins).where("logins.login = ?", login)}
	
	# scope :from_term, -> term  { where("term" => term) if not (term.nil? or term.empty?) }
	# scope :having_status, -> status  { where("status" => status) if not (status.nil? or status.empty?) }
	
	enum role: [:guest, :student, :assistant, :head, :admin]
	
	def self.find_by_login(login)
		if login
			return Login.find_by_login(login).user
		end
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

	def final_grade
		'N/A'
	end
	
	def assign_final_grade(grader)
		# generate hash of  pset_name: submit_object
		subs = self.grades.group_by { |i| i.submit.pset.name }.each_with_object({}) { |(k,v),o| o[k] = v[0] }
		tools = GradeTools.new
		
		tools.log "Calculating\n"
		
		# calc grade from hash
		Settings['grading']['calculation'].each do |name, formula|
			tools.log "- #{name}"
			grade = GradeTools.new.calc_final_grade_formula(subs, formula)
			tools.log "    - result: #{grade}"
			if grade > 0
				final = self.submits.where(pset:Pset.where(name: name).first).count > 0
				if final || grade > 0
					final = self.submits.where(pset:Pset.where(name: name).first).first_or_create
					final.create_grade if !final.grade
					final.grade.grade = grade
					final.grade.grader = grader
					if final.grade.changed?
						final.grade.status = Grade.statuses['finished']
						final.grade.save
					end
				end

			end
		end
		
		return tools.get_log
		
		# save
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
