class Hand < ActiveRecord::Base

	belongs_to :user
	belongs_to :assist, class_name: "User"

	after_create do |hand|
		notifier = Slack::Notifier.new ENV['SLACK_WEBHOOK'], username: hand.user.name
		notifier.ping hand.help_question
	end

end
