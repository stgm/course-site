class Kramdown::Converter::CustomHtml < Kramdown::Converter::Html
	
	##
	# give tables some bootstrap attributes
	#
	def convert_table(el, indent)
		el.attr['class'] = 'kramdown-table'
		super
	end
	
	##
	# prefixes all local image src with the right directory in /public/course
	#
	def convert_img(el, indent)
		if el.attr['alt'] == 'videoplayer'
			return "<div class='embed'><div class='embed-responsive embed-responsive-16by9'><video src='#{cdn_url(el.attr['src'])}' controls width='auto' height='auto' preload='none' class='embed-responsive-item video-js vjs-sublime-skin' data-setup='{}'></div></div>"
		elsif el.attr['alt'] == 'embed'
			return "<div class='embed'><div class='embed-responsive embed-responsive-16by9'><iframe class='embed-responsive-item' src='#{el.attr['src']}'></iframe></div></div>"
		elsif el.attr['src'] && el.attr['src'] !~ /(^[\w]*:|^\/)/
			el.attr['src'] = File.join(@options[:asset_prefix], el.attr['src'])
		end
		super
	end
	
	##
	# prefixes all local links with the right directory in /public/course
	#
	def convert_a(el, indent)
		if @options[:cdn_prefix]
			el.attr['href'] = cdn_url(el.attr['href'])
		end
		# any hrefs not starting with proto: or / or # are relative and 
		# will be prefixed
		if el.attr['href'] && el.attr['href'] !~ /(^[\w]*:|^\/|^\#)/
			el.attr['href'] = File.join(@options[:asset_prefix], el.attr['href'])
		end
		super
	end
	
	##
	# simply abuse the kramdown math markers, transform 
	# them to ASCIImath.js markers
	#
	# def convert_math(el, indent)
	# 	"`#{el.value}`"
	# end
	
	##
	# convert 'bold' text to kbd tag, which will display it as keyboard 
	# entry text
	#
	
	def convert_blockquote(el, opts)
		el.attr['class'] = 'protip'
        format_as_indented_block_html(el.type, el.attr, '<i class="fa fa-2x fa-thumb-tack"></i>' + inner(el, indent), indent)
	end
	
	def convert_p(el, indent)
		if el.children.length == 1 && el.children.first.type == :img && el.children.first.attr['alt'] == 'embed'
			inner(el, indent)
		else
			super
		end
	end
	
	private
	
	def cdn_url(source)
		source.sub(/^cdn:\//, @options[:cdn_prefix])
	end
	
end
