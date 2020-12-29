module ModalHelper

	def link_to(name = nil, options = nil, html_options = {}, &block)
		if html_options.include? :target
			target = html_options[:target]
			html_options.delete :target
			html_options.deep_merge! ({ data: { 'turbo-frame' => target } })
		end
		super(name, options, html_options, &block)
	end

	# def button_to(name = nil, options = nil, html_options = nil, &block)
	# 	if false
	# 		super(name, options, {remote:true}.merge(html_options||{}), &block)
	# 	else
	# 		super
	# 	end
	# end

end
