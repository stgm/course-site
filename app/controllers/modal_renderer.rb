module ModalRenderer
	
	def render_to_modal(options={})
		@partial = action_name
		# @partial = normalized_template
		puts "HIER #{@partial}"
		@header = options[:header]
		@header_partial = options[:header_partial]
		@tooltips = options[:tooltips]
		render 'modal/load_modal.js.erb'
	end
	
	private
	
	def normalized_template
		"#{controller_name}/#{action_name}"
	end
		
end
