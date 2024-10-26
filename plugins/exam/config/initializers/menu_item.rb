# Register the exam menu item using the register_menu_item method

Rails.application.config.to_prepare do
  NavigationHelper.register_menu_item('Exam Admin', '/admin/exams', icon: 'droplet', target: 'modal')
end
