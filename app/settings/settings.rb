class Settings < RailsSettings::Base

    scope :config_files do
        field :course, default: {}
        field :materials, default: {}
        field :grading, default: {}
        field :schedule_grading, default: {}
    end

    scope :accounts do
        field :registration_phase, default: "before"
        field :login_by_email, default: true
        field :exam_current, type: :integer, default: nil
        field :exam_code, default: nil
        field :exam_show_personal, default: false
    end

    scope :site do
        field :git_repo, default: ENV["GITHUB_BASE"]
        field :git_branch, default: ENV["GITHUB_BRANCH"]
        field :send_grade_mails, default: false
        field :room_for_toc
        field :public_schedule

        field :exam_base_url, default: ENV["COURSE_SITE_EXAM_SERVER"] || "https://ide.proglab.nl/exam.html"

        field :hands_allow
        field :hands_only
        field :hands_location
        field :hands_location_type, default: "tafelnummer"
        field :hands_location_bumper
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
        field :ta_overview_allow, default: false
        field :qa_allow
        field :hands_allow
        field :pages_enable_math
        field :webhook_secret
    end

    scope :submit_system do
        # "It's not possible to submit assignments this weekend. Try again from Monday at 10:00."
        field :submit_disabled, default: false, readonly: true
        field :webdav_base
        field :webdav_user
        field :webdav_pass
        field :archive_course_folder
        field :archive_base_folder, default: "Submit", validates: { presence: true }
    end

    field :git_version, default: {}

end
