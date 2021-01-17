class Hands::StatisticsController < ApplicationController

	before_action :authorize
	before_action :require_admin

	layout 'modal'

	def show
		@today = Hand.
			includes(:assist).
			where("created_at > ?", DateTime.yesterday.beginning_of_day).
			order("created_at desc")

		@chart_data = Hand.
			joins(:assist).
			where("hands.created_at > ? and hands.done = ?", Date.today.beginning_of_day, true).
			order("hands.created_at desc").
			group_by(&:assist).
			map do |assist, hands|
				hands.map do |hand|
					[assist.name, hand.claimed_at, hand.updated_at]
				end
		end
		@chart_data = @chart_data.flatten(1)

		date1 = 1.week.ago.beginning_of_day
		@week_data = Hand.
			where(done: true).
			where('claimed_at is not null').
			where('updated_at > ?', date1).
			group_by_hour(:claimed_at).count.
			map { |h,v| { x: h.day , y: Time.zone.utc_to_local(h).hour, r: v } }
	end

end
