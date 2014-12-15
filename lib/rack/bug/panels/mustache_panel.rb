require "rack/bug/panels/mustache_panel/version"

module Rack
  module Bug
    class MustachePanel < Panel
      require "rack/bug/panels/mustache_panel/mustache_extension"

      LIMIT = 10

      # The view is responsible for rendering our panel. While Rack::Bug
      # takes care of the nav, the content rendered by View is used for
      # the panel itself.
      class View < Mustache
        self.path = ::File.dirname(__FILE__) + '/mustache_panel'

        # We track the render times of all the Mustache views on this
        # page load.
        def times
          MustachePanel.times.each_with_object({}) do |obj, key, value|
            obj[key] = value
          end
        end

        # Any variables used in this page load are collected and displayed.
        def variables
          vars = MustachePanel.variables.sort_by { |key, _| key.to_s }
          vars.map do |key, value|
            # Arrays can get too huge. Just show the first 10 (LIMIT) to give you
            # some idea.
            size = value.size

            if value.is_a?(Array) && size > LIMIT
              value = value.first(LIMIT)
              value << "...and #{size - LIMIT} more"
            end

            { :key => key, :value => value.inspect }
          end
        end
      end

      # Clear out our page load-specific variables.
      def self.reset
        Thread.current["rack.bug.mustache.times"] = {}
        Thread.current["rack.bug.mustache.vars"] = {}
      end

      # The view render times for this page load
      def self.times
        Thread.current["rack.bug.mustache.times"] ||= {}
      end

      # The variables used on this page load
      def self.variables
        Thread.current["rack.bug.mustache.vars"] ||= {}
      end

      # The name of this Rack::Bug panel
      def name
        "mustache"
      end

      # The string used for our tab in Rack::Bug's navigation bar
      def heading
        "{{%.2fms}}" % self.class.times.values.reduce(0.0) do |sum, obj|
          sum + obj
        end
      end

      # The content of our Rack::Bug panel
      def content
        View.render
      ensure
        self.class.reset
      end
    end
  end
end
