module User::ChangeLogger
	extend ActiveSupport::Concern

	included do
		after_save :log_changes
	end

	private

	def log_changes
		changes = self.previous_changes.slice('active', 'done', 'status', 'schedule_id', 'alarm', 'group_id', 'role')

		changes.each do |k,new_value|
			text = case k
				when 'active'
					new_value[1] ? "Marked as active" : "Marked as inactive"
				when 'done'
					new_value[1] ? "Marked as done" : "Marked as not done"
				when 'status'
					new_value[1].present? ? "Status set to '#{new_value[1]}'" : "Status cleared"
				when 'schedule_id'
					"Schedule changed to #{self.schedule_name}"
				when 'group_id'
					"Group assignment changed to #{self.group_name}"
				when 'alarm'
					new_value[1] ? "Alarm set" : "Alarm unset"
				when 'role'
					"Activated as #{new_value[1]}"
				end

			self.notes.create(
				text: text,
				author: Current.user,
				log: true
			)
		end
	end
end
