module Plugins
  module Exam
    class Engine < ::Rails::Engine
      isolate_namespace Plugins::Exam

      initializer 'plugins.exam.load_helpers' do
        ActiveSupport.on_load(:action_controller) do
          include Plugins::Exam::ApplicationHelper
        end
      end

      initializer 'plugins.exam.load_middleware' do
        config.app_middleware.use Plugins::Exam::Middleware
      end

      initializer 'plugins.exam.load_routes' do
        Rails.application.routes.prepend do
          mount Plugins::Exam::Engine, at: '/exam'
        end
      end
    end
  end
end
