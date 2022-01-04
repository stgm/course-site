class Submit < ApplicationRecord

	include AutoCheck::Receiver
	include AutoCheck::ScoreCalculator
	include AutoCheck::FeedbackFormatter

	belongs_to :user, touch: true, counter_cache: true
	delegate :name, to: :user, prefix: true, allow_nil: true
	delegate :suspect_name, to: :user, prefix: true, allow_nil: true
	after_create { user.status_active! }

	belongs_to :pset
	delegate :name, to: :pset, prefix: true, allow_nil: true

	has_one :grade, dependent: :destroy
	accepts_nested_attributes_for :grade, update_only: true
	delegate :status, to: :grade, prefix: true, allow_nil: true
	delegate :first_graded, to: :grade, allow_nil: true
	delegate :last_graded, to: :grade, allow_nil: true
	delegate :public?, to: :grade, prefix: true, allow_nil: true

	has_many_attached :files

	serialize :submitted_files, Array  # deprecated for move to active_storage
	serialize :file_contents, Hash     # deprecated for move to active_storage
	serialize :form_contents
	serialize :check_results, default: {}

	# TODO only hide stuff that's not been autograded if autograding is actually enabled
	scope :to_grade,  -> do
		includes(:user, :pset, :grade).
		where(grades: { status: [nil, Grade.statuses[:unfinished]] }).
		where(users: { status: :active }).
		where("psets.automatic = ? or submits.check_results is not null", false).
		order('submits.created_at asc')
	end

	scope :admin_to_grade,  -> do
		includes(:user, :pset, :grade).
		where(grades: { status: [nil, Grade.statuses[:unfinished], Grade.statuses[:finished]] }).
		where(users: { status: :active }).
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

		# reset and unpublish grade
		self.grade.update_columns(grade: nil, status: Grade.statuses[:unfinished]) if self.grade

		self.files.purge
		self.files.attach(attachments.all.values)

	end

	def all_files
		result = []
		# files from old submit system
		result += file_contents.to_a
		# files from new submit system
		result += files.map{ |f| [f.filename.sanitized, f] }
	end

	def all_files_and_form
		result = all_files
		# add form answers
		result = result.unshift(['Form', form_contents]) if form_contents.present?
		return result
	end

	def filenames
		# combine filesnames for submitted files in old and new system
		submitted_files + files.map(&:filename)
	end

	def has_form_response?
		form_contents.present?
	end

	def checkable?
		pset.check_config.present?
	end

	def recheck(host)
		zip = Attachments.new(self.all_files.to_h).zipped
		token = Submit::AutoCheck::Sender.new(zip, self.pset.config['check'], host).start
		self.update(check_token: token)
	end

	def may_be_resubmitted?
		grade.blank? || (grade.public? && grade.any_final_grade.present? && grade.any_final_grade == 0)
	end

    def self.indexed_by_pset_and_user_for(users)
        # @all_indexed_by_pset_and_user ||=
        where(user: users).
        includes(grade: :pset).
        index_by{|i| [i.pset_id, i.user_id]}
    end

	# kill auto-analysis by ActiveStorage
	ActiveStorage::Blob::Analyzable.module_eval do
		def analyze_later
		end

		def analyzed?
			true
		end
	end

end
