module ApplicationHelper

	def page_done_icon(user, pset)
		logger.debug user.inspect
		logger.debug pset.inspect
		if user && pset && Submit.where(:user_id => user.id, :pset_id => pset.id).count > 0
			" <i class='icon-thumbs-up'></i>".html_safe
		else
			""
		end
	end

	class Kramdown::Converter::CustomHtml < Kramdown::Converter::Html
		
		def convert_table(el, indent)
			el.attr['class'] = 'table-padded table-bordered'
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
		Kramdown::Document.new(text, :asset_prefix => page_context.public_url, :coderay_css => :class, :coderay_tab_width => 4, :enable_coderay => true, :coderay_line_numbers => nil).to_custom_html.html_safe
	end
	
	def title()
		(@page && @page.title) || @title
	end

end
