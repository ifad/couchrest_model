require 'rails/generators/named_base'
require 'rails/generators/active_model'
require 'couchrest_model'

module CouchrestModel
  module Generators
    module Extensions #:nodoc:
      # Set the current directory as base for the inherited generators.
      def base_root
        File.dirname(__FILE__)
      end
    end

    class NamedBase < Rails::Generators::NamedBase #:nodoc:
      extend Extensions
    end

    class Base < Rails::Generators::Base #:nodoc:
      extend Extensions
    end
  end
end
