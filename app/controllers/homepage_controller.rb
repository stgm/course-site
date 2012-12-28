class HomepageController < ApplicationController

	before_filter RubyCAS::GatewayFilter
	
	def logout
		RubyCAS::Filter.logout(self)
	end

end
