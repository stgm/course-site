class StatsController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin
	
	def hands
		@today = Hand.includes(:assist).where("created_at > ?", DateTime.yesterday.beginning_of_day).order("created_at desc")
		
		@chart_data = Hand.joins(:assist).where("hands.created_at > ? and hands.done = ?", Date.today.beginning_of_day, true).order("hands.created_at desc").group_by(&:assist).map do |assist, hands|
			hands.map do |hand|
				[assist.name, hand.claimed_at, hand.updated_at]
			end
		end
		
		@chart_data = @chart_data.flatten(1)
		
		# @week_data = Hand.where(done: true).where("updated_at > ?", 1.week.ago).select("strftime('%H',created_at) as the_hour, date(created_at) as the_date").map { |h| { x: h.the_date.remove("-"), y: h.the_hour.to_i+2, r: 1 } }
		# @week_data =  Hand.where(done: true).where("updated_at > ?", 1.week.ago).group_by_hour(:created_at).count.map { |h| [ h.created_at, h.the_hour.to_i+2] }
		@week_data =  Hand.where(done: true).where("updated_at > ?", 1.week.ago).group_by_hour(:created_at).count.map { |h,v| { x: h.day, y: h.hour.to_i+2, r: v } }
	end

end
