module User::ChangeLogger
	extend ActiveSupport::Concern

	included do
		after_save :log_changes
	end

	private

	def log_changes
		changes = self.previous_changes.select{|k,v| ['active', 'done', 'status','schedule_id','alarm'].include?(k)}
		if changes.any?
			self.notes.create(text: changes.collect{|k,v| "#{k.humanize} set to #{v[1]}  "}.join, author: Current.user, log: true)
		end
	end
end
