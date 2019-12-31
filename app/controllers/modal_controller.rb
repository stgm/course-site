class ModalController < ApplicationController

	def render_to_modal(options={})
		@partial = action_name
		@header = options[:header]
		@header_partial = options[:header_partial]
		@tooltips = options[:tooltips]
		render "load_modal"
	end
	
end
