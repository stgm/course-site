# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )
Rails.application.config.assets.precompile += %w( nbpreview/nbpreview.js nbpreview/vendor/es5-shim.min.js nbpreview/vendor/prism.min.js nbpreview/vendor/marked.min.js nbpreview/vendor/ansi_up.min.js nbpreview/vendor/katex.min.js nbpreview/vendor/katex-auto-render.min.js )
Rails.application.config.assets.precompile += %w( video-js.swf vjs.eot vjs.svg vjs.ttf vjs.woff )
