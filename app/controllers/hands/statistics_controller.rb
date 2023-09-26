class Hands::StatisticsController < ApplicationController

	before_action :authorize
	before_action :require_admin

	layout 'modal'

	def show
		@today = Hand.
			includes(:assist).
			where("created_at > ? OR done = ?", DateTime.yesterday.beginning_of_day, false).
			order("created_at desc")

		@chart_data = Hand.
			joins(:assist).
			where("hands.created_at > ? and hands.done = ? and hands.claimed_at is not null", Date.today.beginning_of_day, true).
			order("hands.created_at desc").
			group_by(&:assist).
			map do |assist, hands|
				hands.map do |hand|
					[assist.name, hand.claimed_at, hand.updated_at]
				end
		end
		@chart_data = @chart_data.flatten(1)
		@chart_groups = @chart_data.group_by(&:first)
		@chart_start = @chart_data.map(&:second).compact.sort.first
		@chart_end = @chart_data.map(&:third).compact.sort.last

		date1 = 1.week.ago.beginning_of_day
		@week_data = Hand.
			where(done: true).
			where('claimed_at is not null').
			where('updated_at > ?', date1).
			group_by_hour(:claimed_at).count.
			map { |h,v| { x: h.day , y: h.hour, r: v } }
	end

end
