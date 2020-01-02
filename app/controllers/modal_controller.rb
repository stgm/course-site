class ModalController < ApplicationController
	
	before_action :set_remote_links

	def render_to_modal(options={})
		@partial = action_name
		# @partial = normalized_template
		puts "HIER #{@partial}"
		@link_back = options[:link_back]
		@link_description = options[:link_description]
		@header = options[:header]
		@header = helpers.link_to(@link_description, @link_back, remote: true) + ' / ' + @header if @link_back
		@header_partial = options[:header_partial]
		@tooltips = options[:tooltips]
		render 'load_modal'
	end
	
	private
	
	def normalized_template
		"#{controller_name}/#{action_name}"
	end
	
	def set_remote_links
		if request.xhr?
			@remote_links = true
		end
	end
	
end
