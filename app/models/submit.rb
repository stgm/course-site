class Submit < ApplicationRecord
	
	include AutoCheck::Receiver
	include AutoCheck::ScoreCalculator
	include AutoCheck::FeedbackFormatter

	belongs_to :user, touch: true
	delegate :name, to: :user, prefix: true, allow_nil: true
	delegate :suspect_name, to: :user, prefix: true, allow_nil: true

	belongs_to :pset
	delegate :name, to: :pset, prefix: true, allow_nil: true

	has_one :grade, dependent: :destroy
	accepts_nested_attributes_for :grade, update_only: true
	delegate :status, to: :grade, prefix: true, allow_nil: true
	delegate :first_graded, to: :grade, allow_nil: true
	delegate :last_graded, to: :grade, allow_nil: true
	
	has_many_attached :files

	serialize :submitted_files, Array  # deprecated for move to active_storage
	serialize :file_contents, Hash     # deprecated for move to active_storage
	serialize :form_contents
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

	def to_partial_path
		# This very nice rails feature allows us to decide whether a form or
		# a read-only presentation should be rendered. Simply use "render
		# @grade_object" and this method will be consulted.
		(grade.blank? || grade.unfinished?) ? 'submits/form' : 'submits/grade'
	end

	def sortable_date
		submitted_at
	end

	def record(used_login: nil, archive_folder_name: nil, url: nil, attachments: nil, check_token: nil, form_contents: nil)
		# basic info
		self.submitted_at = Time.now
		self.used_login = used_login
		self.folder_name = archive_folder_name

		# attachments
		self.url = url
		
		# remove old attachments
		self.submitted_files = nil # TODO deprecated for migration to activestorage
		self.file_contents = nil   # TODO deprecated for migration to activestorage
		self.form_contents = form_contents

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

		self.files.purge
		self.files.attach(attachments.all.values)

	end

	def all_files
		result = []
		result << ['Form', form_contents] if form_contents.present?
		result += file_contents.to_a
		result += files_for_module
		result += files.map{ |f| [f.filename.sanitized+'.', f] }
	end
	
	# retrieve all submitted file contents for all submits from a particular module (for this user)
	def files_for_module
		user.submits.where(pset: pset.child_psets).map do |submit|
			submit.all_files.map do |f|
				# prefix the filename with some of the submit info, for display purposes
				["<small>(#{(submit.correctness_score||0)*100}% #{submit.submitted_at.strftime('%a-%-d %R')})</small> #{submit.pset.name}/#{f[0]}", f[1]]
			end
		end.flatten(1)
	end

	def filenames
		submitted_files + files.map(&:filename)
	end

	def has_form_response?
		form_contents.present?
	end
	
	def checkable?
		pset.check_config.present?
	end
	
	def recheck(host)
		zip = Attachments.new(self.file_contents).zipped
		token = AutoCheck::Sender.new(zip, self.pset.config['check'], host).start
		self.update(check_token: token)
	end
	
	def may_be_resubmitted?
		grade.blank? || (grade.public? && grade.any_final_grade.present? && grade.any_final_grade == 0)
	end
	
end
