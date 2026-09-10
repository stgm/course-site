class Pset < ApplicationRecord

    belongs_to :page, optional: true

    has_one :exam
    has_many :submits
    has_many :grades, through: :submits

    # TODO remove?
    enum :grade_type, { integer: 0, float: 1, pass: 2, percentage: 3, points: 4 }

    serialize :files, coder: YAML, type: Hash
    serialize :config, coder: YAML, type: Hash

    def all_filenames
        files.map { |h, f| f }.flatten.uniq
    end

    # provides just the config from submit.yml (filenames to be submitted)
    def submit_config(schedule = nil)
        config
    end

    def url
        config['url']
    end

    def git_repo
        config['git_repo']
    end

    # URL of a lab directory handed to the external editor for an exam; when set,
    # the editor takes files and instructions from there instead of from the
    # exam's own templates
    def lab_config
        config['lab_config']
    end

    # provides the full grading config based on general and schedule-specific
    # configs
    def grading_config(schedule)
        schedule.grading_config.grades[name]
    end

    def is_final_grade?
        self.final
    end

end
