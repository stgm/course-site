module User::ChangeLogger
	extend ActiveSupport::Concern

	included do
		after_save :log_changes
	end

	private

	def log_changes
		changes = self.previous_changes.slice(
			'status',
			'status_description',
			'schedule_id',
			'alarm',
			'group_id', 
			'role')

		changes.each do |k,new_value|
			text = case k
				when 'status'
					"Marked as #{new_value[1]}"
				when 'status_description'
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
