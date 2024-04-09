module User::Schedulizable

    extend ActiveSupport::Concern

    included do
        belongs_to :schedule, optional: true#, default: -> { Schedule.default }
        belongs_to :current_module, class_name: "ScheduleSpan", optional: true

        delegate :name, to: :schedule, prefix: true, allow_nil: true

        before_save :set_current_module, if: :schedule_id_changed?
    end

    def valid_schedule?
        self.schedule.present?
    end

    def grading_config
        schedule&.grading_config || GradingConfig.base
    end

    def check_current_schedule!
        # if schedule.blank?
        #     set_current_schedule
        #     save! if persisted?
        # end
        self.schedule
    end

    def set_current_schedule!
        if !self.admin?
            self.schedule = Schedule.default
        else
            self.schedule = Schedule.default || Schedule.first
        end
        save!
    end

    def check_current_module!
        check_current_schedule!
        if !valid_current_module?
            set_current_module
            save! if persisted?
        end
        self.current_module
    end

    def valid_current_module?
        return false if !schedule.present?                 # there is no schedule
        return false if current_module.nil?                # there is a schedule, but no module
        return false if !staff? && !current_module.accessible? # there is something, but access is currently denied
        return true
    end

    def set_current_module
        if self.schedule && span = self.schedule.default_span(self.student?)
            self.current_module = span
        else
            self.current_module_id = nil
        end
    end

    def reset_group
        self.group_id = nil
    end

end
