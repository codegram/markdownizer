require 'rails/generators'

module Markdownizer
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc "Copy Markdownizer code highlighting stylesheets"

      source_root File.expand_path(File.join(File.dirname(__FILE__), 'templates'))

      def copy_stylesheet_file
        copy_file 'coderay.css', 'app/assets/stylesheets/markdownizer.css'
      end
    end
  end
end
