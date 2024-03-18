class Pset < ApplicationRecord

    belongs_to :page, optional: true

    has_many :submits
    has_many :grades, through: :submits

    # TODO remove?
    enum grade_type: [:integer, :float, :pass, :percentage, :points]

    serialize :files, Hash
    serialize :config, Hash

    def all_filenames
        files.map { |h,f| f }.flatten.uniq
    end

    # provides just the config from submit.yml (filenames to be submitted)
    def submit_config(schedule=nil)
        config
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
