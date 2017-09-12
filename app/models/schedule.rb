class Schedule < ActiveRecord::Base

	has_many :schedule_spans, dependent: :destroy
	belongs_to :current, class_name: "ScheduleSpan", foreign_key: "current_schedule_span_id"
	has_many :users
	has_many :hands, through: :users
	has_many :grades, through: :users

	#
	# this method accepts the yaml contents of a schedule file
	#
	def load(contents)

		# save the NAME of the current schedule item, to restore later
		backup_position = current.name if current
		
		# delete al items
		schedule_spans.delete_all
		
		# create all items
		contents.each do |name, items|
			span = schedule_spans.where(name: name).first_or_initialize
			span.content = items.to_yaml
			span.save
		end
		
		# restore 'current' item
		update_attribute(:current, backup_position && self.schedule_spans.find_by_name(backup_position))
		
	end

end
