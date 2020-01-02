module ModalHelper
	def link_to(name = nil, options = nil, html_options = nil, &block)
		if @remote_links
			super(name, options, {remote:true}.merge(html_options||{}))
		else
			super
		end
	end
end
