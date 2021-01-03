module Schedulizable

	extend ActiveSupport::Concern

	included do
		belongs_to :schedule, optional: true
		belongs_to :current_module, class_name: "ScheduleSpan", optional: true

		delegate :name, to: :schedule, prefix: true, allow_nil: true

		before_save :reset_group, if: :schedule_id_changed?
		before_save :reset_current_module, if: :schedule_id_changed?
	end

	def check_current_schedule!
		update!(schedule: Schedule.default) if persisted? && schedule.blank?
		schedule
	end

	def check_current_module!
		check_current_schedule!
		reset_current_module if !valid_current_module?
		save! if persisted? && !valid_current_module?

		if schedule.blank?
			nil
		elsif schedule.self_service
			@current_module = current_module || schedule.current
		else
			@current_module = schedule.current
		end
	end

	def valid_current_module?
		return false if !schedule.present?
		return false if current_module.nil?
		return false if !staff? && !current_module.public?
		return true
	end

	def reset_current_module
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
