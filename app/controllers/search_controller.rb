class SearchController < ApplicationController
	
	def autocomplete
		render json: Settings['keyword_index'].keys.find_all { |k| k.match?(params[:query])}
	end
	
	def query
		subpage_ids = Settings['keyword_index'][params[:query]]
		@subpages = Subpage.find(subpage_ids)
		respond_to do |format|
			format.js { render 'form' }
		end
	end
	
	def subpage
		subpage = Subpage.find(params[:id])
		@page = subpage.page
		@document = subpage.content
		respond_to do |format|
			format.js { render 'subpage' }
		end
	end

end
