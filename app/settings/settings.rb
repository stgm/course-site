class Settings < RailsSettings::Base

    scope :config_files do
        field :course, default: {}
        field :materials, default: {}
        field :grading, default: {}
    end

    scope :accounts do
        field :registration_phase, default: 'before'
        field :login_by_email, default: true
    end

    scope :site do
        field :git_repo
        field :git_branch
        field :send_grade_mails, default: false
        field :room_for_toc
        field :public_schedule

        field :hands_allow
        field :hands_location
        field :hands_bumper
        field :hands_link
        field :hands_groups
        field :hands_show_non_questions
    end

    scope :cache do
        field :page_tree
        field :tests_present
        field :cached_user_paste
    end

    scope :features do
        field :hands_allow
        field :pages_enable_math
        field :webhook_secret
    end

    scope :archival do
        field :webdav_base
        field :webdav_user
        field :webdav_pass
        field :archive_course_folder
        field :archive_base_folder, default: "Submit", validates: { presence: true }
    end

    field :git_version, default: {}

end
