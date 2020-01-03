module ModalHelper
	def link_to(name = nil, options = nil, html_options = nil, &block)
		if request.xhr?
			super(name, options, {remote:true}.merge(html_options||{}))
		else
			super
		end
	end
end
