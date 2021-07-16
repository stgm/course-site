class Tests::TestsController < ApplicationController

	before_action :authorize
	before_action :require_senior
	
	layout 'modal'

	def index
		@psets = Pset.where(test: true).order(:order)
	end

end
