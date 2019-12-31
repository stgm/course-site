class Tests::TestsController < ApplicationController

	before_action :authorize
	before_action :require_senior
	before_action :load_navigation

	def index
		@psets = Pset.where(test: true).order(:order)
	end

end
