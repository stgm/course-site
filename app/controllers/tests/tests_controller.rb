class Tests::TestsController < ModalController

	before_action :authorize
	before_action :require_senior
	before_action :load_navigation

	def index
		@psets = Pset.where(test: true).order(:order)
		render_to_modal header: 'Test administration'
	end

end
