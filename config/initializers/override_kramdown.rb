class Kramdown::Converter::CustomHtml < Kramdown::Converter::Html
	
	##
	# give tables some bootstrap attributes
	#
	def convert_table(el, indent)
		el.attr['class'] = 'table-padded table-bordered'
		super
	end
	
	##
	# prefixes all local image src with the right directory in /public/course
	#
	def convert_img(el, indent)
		if el.attr['src'] && el.attr['src'] !~ /(^[\w]*:|^\/)/
			el.attr['src'] = File.join(@options[:asset_prefix], el.attr['src'])
		end
		super
	end
	
	##
	# prefixes all local links with the right directory in /public/course
	#
	def convert_a(el, indent)
		# any hrefs not starting with proto: or / or # are relative and will be prefixed
		if el.attr['href'] && el.attr['href'] !~ /(^[\w]*:|^\/|^\#)/
			el.attr['href'] = File.join(@options[:asset_prefix], el.attr['href'])
		end
		super
	end
	
	##
	# simply abuse the kramdown math markers, transform them to ASCIImath.js markers
	#
	def convert_math(el, indent)
		"`#{el.value}`"
	end
	
end
