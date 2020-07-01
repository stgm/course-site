module ApplicationHelper

	def page_done_icon(user, pset)
		if user && pset && Submit.where(:user_id => user.id, :pset_id => pset.id).count > 0
			" <span class='glyphicon glyphicon-thumbs-up'></span>".html_safe
		else
			""
		end
	end
	
	def date_span_with_title(date)
		"<span title=\"#{date.strftime("%A %d %b %Y %R")}\">#{time_ago_in_words(date)} #{t(:ago)}</span>".html_safe
	end

	def markdown(text, page_context)
		Kramdown::Document.new(text,
		                       :auto_ids => true,
		                       :asset_prefix => page_context.public_url,
		                       :cdn_prefix => Course.cdn_prefix,
		                       :parse_block_html => true,
		                       :toc_levels => 2..3,
		                       :math_engine => nil,
		                       :coderay_css => :class,
		                       :coderay_tab_width => 4,
		                       :enable_coderay => true,
		                       :coderay_line_numbers => nil).to_custom_html.html_safe
	end
	
	def simple_markdown(text)
		return text && Kramdown::Document.new(text,
		                       :auto_ids => true,
		                       :parse_block_html => true,
		                       :toc_levels => 2..3,
		                       :coderay_css => :class,
		                       :coderay_tab_width => 4,
		                       :enable_coderay => true,
		                       :coderay_line_numbers => nil).to_custom_html.html_safe
	end
	
	def title()
		@title || (@page && @page.title)
	end
	
	def class_if(condition, classes)
		condition ? " " + classes : ""
	end
	
	def class_if_else(condition, classes, else_classes)
		condition ? " " + classes : " " + else_classes
	end
	
	def form_tag_if(condition, url_for_options = {}, options = {}, &block)
		if condition
			form_tag(url_for_options, options, &block)
		else
			capture(&block)
		end
	end
	
	# convert the contents from contents.yml (available as a Hash) into a nested list of links
	#
	def links_to_ul(list)
		items = []
		
		list.each do |item, content|
			if content.is_a?(Hash)
				# a Hash means subitems, so create a caption and recurse
				items << content_tag(:li, insert_badge(item), class: "nav-item small mb-1 mt-2")
				items << content_tag(:li, links_to_ul(content), class: "nav-item")
			elsif content.is_a?(String)
				# a String means that we have a link with title
				items << content_tag(:li, check_box_tag(:item, 'ding', false, class: 'float-left flex-shrink-0 d-block m-2') + link_to(insert_badge(item), content, remote: false, class: "nav-link py-2 flex-fill rounded-right", style: "padding-left: 0.25rem !important;"), class: "nav-item bg-light p-0 rounded mb-1 d-flex align-items-center")
			elsif content.nil?
				# a nil means a caption without a link
				items << content_tag(:li, link_to(insert_badge(item), '#', remote: false, class:"nav-link disabled"), class: "nav-item")
			end
				
		end
		
		content_tag :ul, items.join.html_safe, class: "nav p-0"
	end
	
	def material_links_to_li(list, path="")
		items = []
		
		list.each do |item, content|
			if content.is_a?(Hash)
				# a Hash means subitems, so create a caption and recurse
				link = link_to bootstrap_icon('chevron-right', class: 'chevron d-none d-lg-inline-block') + item.humanize, "#collapse-materials-#{path.parameterize}-#{item.parameterize}", class: "nav-link", data: { toggle: "collapse" }, role: "button", aria: { haspopup: "true", expanded: "false" }
				list = content_tag(:ul, material_links_to_li(content,path+"-#{item.parameterize}"), class: 'nav collapse', id: "collapse-materials-#{path.parameterize}-#{item.parameterize}")
				items << content_tag(:li, link + list)
				# items << content_tag(:li,   , class: "nav p-0", class: "nav-item")
			elsif content.is_a?(String)
				# a String means that we have a link with title
				items << content_tag(:li, link_to(insert_badge(item), "/#{content}", remote: false, class: "nav-link"), class: "nav-item")
			elsif content.nil?
				# a nil means a caption without a link
				items << content_tag(:li, link_to(insert_badge(item), '#', remote: false, class:"nav-link disabled"), class: "nav-item")
			end
				
		end
		
		items.join.html_safe
		# content_tag :ul, items.join.html_safe, class: "nav p-0"
	end
	
	
	# convert [markup] in a string into a bootstrap badge span
	#
	def insert_badge(description)
		description.sub('[', '<span class="badge">').sub(']', '</span>').html_safe
	end
	
	def is_local_ip?
		# begin
		# 	location = Resolv.getname(request.remote_ip)
		# rescue Resolv::ResolvError
		# 	location = "untraceable"
		# end
		# puts "loc" + location
		# return location =~ /^(wcw|1x).*uva.nl$/ || location == 'localhost'
		# puts request.remote_ip
		return !!(request.remote_ip =~ /^145\.18\..*$/) ||
		       !!(request.remote_ip =~ /^145\.109\..*$/) ||
			   !!(request.remote_ip =~ /^195\.169\..*$/) ||
			   !!(request.remote_ip =~ /^100\.70\..*$/) ||
			   request.remote_ip == '::1' ||
			   request.remote_ip == '127.0.0.1'
	end
	
	def menu_group(name=nil, &block)
		[
			name && tag.h6(name, class: 'dropdown-header pl-0 pl-md-4'),
			capture(&block),
			tag.div(class: 'dropdown-divider d-none d-md-block')
		].
		compact.join.html_safe
	end
	

	def menu_link(title, path, icon: '', context: :menu, condition: true, **options)
		return nil if !condition
		link_to bootstrap_icon(icon, class: 'mr-2', width: 16, height: 16, style: 'vertical-align:text-bottom') + title, path, options
	end

	def icon(name, **options)
		if name
			image_tag "/icons/#{name}.svg", { size: '20x20', title: name.capitalize, class: 'mr-1', style: 'vertical-align: -4px;' }.merge(options)
		else
			tag.span('', class: 'mr-2', style: 'display: inline-block; width:20px; height:20px')
		end
	end
	
	def bootstrap_icon(name, **options)
		tag.svg({class:'bi', width:20, height:20, fill:'currentColor'}.merge(options)) do
		  "<use xlink:href=\"/icons/bootstrap-icons.svg##{name}\"/>".html_safe
		end
	end
	
	# convert [name] in a string into a bootstrap icon
	#
	def insert_icon(description)
		if match = description.match(/\[([^\]]+)\] ?(.*)/)
			icon_name = match[1]
			rest = match[2]
			return bootstrap_icon(icon_name) + " " + rest
		else
			return description
		end
	end
	
end
