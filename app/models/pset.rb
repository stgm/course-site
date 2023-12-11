class Pset < ApplicationRecord

    belongs_to :page, optional: true

    has_many :submits
    has_many :grades, through: :submits

    enum grade_type: [:integer, :float, :pass, :percentage, :points]

    serialize :files, Hash
    serialize :config, Hash

    def all_filenames
        files.map { |h,f| f }.flatten.uniq
    end

    def config
        super.merge GradingConfig.grades[name].to_h
    end

    def deadline
        begin
            Time.zone.strptime(config['deadline'], '%d/%m/%y %H:%M')
        rescue
            nil
        end
    end

    def deadline_hard?
        !!config['deadline_hard']
    end

    def submittable?
        # no hard deadlines, or no deadline for pset, or deadline not passed
        !(Course.deadlines_hard? && deadline&.past?) &&
        !(self.config['deadline_hard'] && deadline&.past?)
    end

    def submit_from(user)
        Submit.where(:user_id => user.id, :pset_id => id).first
    end

    def check_config
        config && config['check']
    end

    def is_final_grade?
        self.name.in? GradingConfig.final_grade_names
    end

end
