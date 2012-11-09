module Cinch
  module Plugins
    class PluginWatcher
      include Cinch::Plugin
      
      def initialize(*args)
        super
        auto_reload_plugins
      end

      def load_plugin(plugin, mapping)
        mapping ||= plugin.gsub(/(.)([A-Z])/) { |_|
          $1 + "_" + $2
        }.downcase # we downcase here to also catch the first letter

        file_name = "bot/plugins/core/#{mapping}.rb"
        unless File.exist?(file_name)
          @bot.loggers.error "Could not auto-load #{plugin} because #{file_name} does not exist."
          return
        end

        begin
          load(file_name)
        rescue
          @bot.loggers.error "Could not auto-load #{plugin}."
          raise
        end

        begin
          const = Cinch::Plugins.const_get(plugin)
        rescue NameError
          return
        end

        @bot.plugins.register_plugin(const)
      end

      def unload_plugin(plugin)
        begin
          plugin_class = Cinch::Plugins.const_get(plugin)
        rescue NameError
          @bot.loggers.error "Could not auto-unload #{plugin} because no matching class was found."
          return
        end

        @bot.plugins.select {|p| p.class == plugin_class}.each do |p|
          @bot.plugins.unregister_plugin(p)
        end

        ## FIXME not doing this at the moment because it'll break
        ## plugin options. This means, however, that reloading a
        ## plugin is relatively dirty: old methods will not be removed
        ## but only overwritten by new ones. You will also not be able
        ## to change a classes superclass this way.
        # Cinch::Plugins.__send__(:remove_const, plugin)

        # Because we're not completely removing the plugin class,
        # reset everything to the starting values.
        plugin_class.hooks.clear
        plugin_class.matchers.clear
        plugin_class.listeners.clear
        plugin_class.timers.clear
        plugin_class.ctcps.clear
        plugin_class.react_on = :message
        plugin_class.plugin_name = nil
        plugin_class.help = nil
        plugin_class.prefix = nil
        plugin_class.suffix = nil
        plugin_class.required_options.clear

        @bot.loggers.info "Successfully auto-unloaded #{plugin}"
      end

      def reload_plugin(plugin, mapping)
        unload_plugin(plugin)
        load_plugin(plugin, mapping)
      end

      def auto_reload_plugins
        Thread.new {
          Listen.to('bot/plugins/core', :filter => /\.rb$/, :relative_paths => true) do |modified, added, removed|
            if modified
              modified.each do |class_file|
                class_name = class_file.split('_').map{|e| e.capitalize}.join.chomp(File.extname(class_file))
                reload_plugin(class_name, nil)
              end
            end
          end
        }
        @bot.loggers.info "Now watching for plugin modifications."
      end
    end
  end
end