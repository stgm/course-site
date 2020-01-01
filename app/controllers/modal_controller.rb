class ModalController < ApplicationController

	def render_to_modal(options={})
		@partial = action_name
		@link_back = options[:link_back]
		@link_description = options[:link_description]
		@header = options[:header]
		@header = helpers.link_to(@link_description, @link_back, remote: true) + ' / ' + @header if @link_back
		@header_partial = options[:header_partial]
		@tooltips = options[:tooltips]
		render 'load_modal'
	end
	
end
