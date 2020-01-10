class Tests::TestsController < ApplicationController

	before_action :authorize
	before_action :require_senior

	def index
		@psets = Pset.where(test: true).order(:order)
		render_to_modal header: 'Test administration'
	end

end
