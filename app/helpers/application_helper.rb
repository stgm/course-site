module ApplicationHelper

	class Kramdown::Converter::CustomHtml < Kramdown::Converter::Html
		
		def convert_table(el, indent)
			el.attr['class'] = 'table'
			super
		end
		
		def convert_img(el, indent)
			el.attr['src'] = File.join(@options[:asset_prefix], el.attr['src'])
			super
		end
		
		def convert_a(el, indent)
			if el.attr['href'] && el.attr['href'] !~ /^http:/
				el.attr['href'] = File.join(@options[:asset_prefix], el.attr['href'])
			end
			super
		end
		
		# TODO: want to center maths
		# def convert_math(el, indent)
		# 	block = (el.options[:category] == :block)
		# 	value = (el.value =~ /<|&/ ? "% <![CDATA[\n#{el.value} %]]>" : el.value)
		# 	"<div class=\"maths\"><script type=\"math/tex#{block ? '; mode=display' : ''}\">#{value}</script></div>#{block ? "\n" : ''}"
		# end
		
	end

	def markdown(text, page_context)
		# pass public parl URL to the image converter
		# :image_prefix is defined in config/application.rb
		Kramdown::Document.new(text, :asset_prefix => page_context.public_url, :coderay_tab_width => 4, :enable_coderay => true, :coderay_line_numbers => nil).to_custom_html.html_safe
	end

end
