class StatsController < ApplicationController

	before_filter CASClient::Frameworks::Rails::Filter
	before_filter :require_admin
	
	def hands
		@today = Hand.includes(:assist).where("created_at > ?", DateTime.now.beginning_of_day).order("created_at desc")
	end

end
