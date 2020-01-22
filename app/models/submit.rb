class Submit < ApplicationRecord
	
	include AutoCheck::Receiver
	include AutoCheck::ScoreCalculator
	include AutoCheck::FeedbackFormatter

	belongs_to :user
	delegate :name, to: :user, prefix: true, allow_nil: true
	delegate :suspect_name, to: :user, prefix: true, allow_nil: true

	belongs_to :pset
	delegate :name, to: :pset, prefix: true, allow_nil: true

	has_one :grade, dependent: :destroy
	delegate :status, to: :grade, prefix: true, allow_nil: true
	delegate :first_graded, to: :grade, allow_nil: true
	delegate :last_graded, to: :grade, allow_nil: true

	serialize :submitted_files
	serialize :file_contents
	serialize :check_results

	# TODO only hide stuff that's not been autograded if autograding is actually enabled
	scope :to_grade,  -> do
		includes(:user, :pset, :grade).
		where(grades: { status: [nil, Grade.statuses[:unfinished]] }).
		where(users: { active: true }).
		where("psets.automatic = ? or submits.check_results is not null", false).
		order('submits.created_at asc')
	end

	scope :admin_to_grade,  -> do
		includes(:user, :pset, :grade).
		where(grades: { status: [nil, Grade.statuses[:unfinished], Grade.statuses[:finished]] }).
		where(users: { active: true }).
		where("psets.automatic = ? or submits.check_results is not null", false).
		order('submits.created_at asc')
	end
	
	def record(used_login: nil, archive_folder_name: nil, url: nil, attachments: nil, check_token: nil)
		# basic info
		self.submitted_at = Time.now
		self.used_login = used_login
		self.folder_name = archive_folder_name

		# attachments
		self.url = url
		self.submitted_files = attachments.file_names
		self.file_contents = attachments.presentable_file_contents
		
		# reset auto checks
		self.check_token = check_token
		self.check_results = nil
		self.auto_graded = false

		self.save
		
		user.update(last_submitted_at: self.submitted_at)

		# update the submission for the parent module, if there is one
		if pset.parent_pset
			Submit.where(user: self.user, pset: pset.parent_pset).first_or_initialize.update(submitted_at:Time.now)
		end

		# reset and unpublish grade
		self.grade.update_columns(grade: nil, status: Grade.statuses[:unfinished]) if self.grade
	end
	
end
