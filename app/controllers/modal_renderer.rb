module ModalRenderer
	
	def render_to_modal(options={})
		@partial = options[:action] || action_name
		@header = options[:header]
		@header_partial = options[:header_partial]
		@tooltips = options[:tooltips]
		@in_place_editing = options[:in_place_editing]
		render 'load_modal.js.erb'
	end
	
	def redirect_js(location: nil)
		render partial: 'js_redirector', locals: { location: location }
	end
	
	private
	
	def normalized_template
		"#{controller_name}/#{action_name}"
	end
		
end
