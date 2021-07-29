module ApplicationHelper

	def html_tag_with_language(&block)
		if Course.language
			tag.html(lang: Course.language, &block)
		else
			tag.html(&block)
		end
	end

	def date_span_with_title(date)
		"<span title=\"#{date.strftime("%A %d %b %Y %R")}\">#{time_ago_in_words(date)} #{t(:ago)}</span>".html_safe
	end

	def markdown(text, page_context)
		Kramdown::Document.new(text,
		                       :auto_ids => true,
		                       :asset_prefix => page_context.public_url,
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

	def title
		"#{@title} - #{Course.long_name}"
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

		if list.is_a?(Hash)
			list.each do |item, content|
				if content.is_a?(Hash)
					# a Hash means subitems, so create a caption and recurse
					items << content_tag(:li, insert_badge(item), class: "nav-text")
					items << content_tag(:li, links_to_ul(content), class: "nav-item")
				elsif content.is_a?(String)
					# a String means that we have a link with title
					content = toggle_progress_form(content) + link_to(insert_badge(item), content, class: "nav-link", target: content =~ /^http/i ? '_blank' : nil)
					items << content_tag(:li, content, class: "nav-link-item")
				elsif content.is_a?(Array)
					items << array_of_links_to_ul(content)
				elsif content.nil?
					# a nil means a caption without a link
					items << content_tag(:li, link_to(insert_badge(item), '#', class:"nav-link disabled"), class: "nav-item")
				end
			end
		elsif list.is_a?(Array)
			items << array_of_links_to_ul(list)
		end

		content_tag :ul, items.join.html_safe, class: "nav"
	end
	
	def array_of_links_to_ul(content)
		# this pulls in any links from module definitions, combines into hash and renders
		all_modules = SubModule.where(name:content).sort_by{|m| content.index(m.name)}
		# combine the content links into a single hash
		combined_content = all_modules.map(&:content_links).reduce({}, :merge)
		return content_tag(:li, links_to_ul(combined_content), class: "nav-item")
	end
	
	def material_links_to_li(list, path="")
		items = []
		
		list.each do |item, content|
			if content.is_a?(Hash)
				# a Hash means subitems, so create a caption and recurse
				link = link_to bootstrap_icon('chevron-right', class: 'chevron d-none d-lg-inline-block') + item.humanize, "#collapse-materials-#{path.parameterize}-#{item.parameterize}", class: "nav-link", data: { 'bs-toggle': "collapse" }, role: "button", aria: { haspopup: "true", expanded: "false" }
				list = content_tag(:ul, material_links_to_li(content,path+"-#{item.parameterize}"), class: 'nav collapse', id: "collapse-materials-#{path.parameterize}-#{item.parameterize}")
				items << content_tag(:li, link + list)
				# items << content_tag(:li,   , class: "nav p-0", class: "nav-item")
			elsif content.is_a?(String)
				# a String means that we have a link with title
				items << content_tag(:li, link_to(insert_badge(item), "/#{content}", class: "nav-link"), class: "nav-item")
			elsif content.nil?
				# a nil means a caption without a link
				items << content_tag(:li, link_to(insert_badge(item), '#', class:"nav-link disabled"), class: "nav-item")
			end
				
		end
		
		items.join.html_safe
		# content_tag :ul, items.join.html_safe, class: "nav p-0"
	end

	# create a remote form for toggling a user's progress for a page
	def toggle_progress_form(page_name)
		form_for(:progress, url: profile_save_progress_path(), remote: true) do |form|
			form.check_box(page_name,
				{
					remote: true,
					checked: current_user.progress[page_name],
					id: "progress_#{page_name.parameterize}_check",
					class: "sform-check-input m-2",
					onclick: "Rails.fire(this.form, 'submit');"
				}
			)
		end
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
		# return location =~ /^(wcw|1x).*uva.nl$/ || location == 'localhost'
		return !!(request.remote_ip =~ /^145\.18\..*$/) ||
		       !!(request.remote_ip =~ /^145\.109\..*$/) ||
			   !!(request.remote_ip =~ /^195\.169\..*$/) ||
			   !!(request.remote_ip =~ /^100\.70\..*$/) ||
			   request.remote_ip == '::1' ||
			   request.remote_ip == '127.0.0.1'
	end
	
	def menu_group(name=nil, &block)
		[
			name && tag.h6(name, class: 'dropdown-header'),
			capture(&block),
			tag.div(class: 'dropdown-divider')
		].
		compact.join.html_safe
	end
	

	def menu_link(title, path, icon: '', context: :menu, condition: true, target: nil, **options)
		return nil if !condition
		options.merge! data: { 'turbo-frame' => target } if target
		if options[:method].present?
			button_to path, options.merge(class: 'dropdown-item') do
				bootstrap_icon(icon, class: 'me-2', width: 16, height: 16, style: 'vertical-align:text-bottom') + title
			end
		else
			link_to bootstrap_icon(icon, class: 'me-2', width: 16, height: 16, style: 'vertical-align:text-bottom') + title, path, options
		end
	end

	def icon(name, **options)
		if name
			image_tag "/icons/#{name}.svg", { size: '20x20', title: name.capitalize, class: 'me-1', style: 'vertical-align: -4px;' }.merge(options)
		else
			tag.span('', class: 'me-2', style: 'display: inline-block; width:20px; height:20px')
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
			return icon_with_label bootstrap_icon(icon_name), rest
		else
			return description
		end
	end
	
	def icon_with_label(icon, label)
		"#{icon}<small>#{label}</small>".html_safe
	end
	
end
