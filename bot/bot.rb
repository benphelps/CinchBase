# Plugins
require_relative 'plugins/core/plugin_watcher'
# load other plugins here before you call them down there

bot = Cinch::Bot.new do
  configure do |c|
    c.server = ""
    c.channels = ["#phelps"]
    c.plugins.plugins = [
      Cinch::Plugins::PluginWatcher,
      # put plugins here, class name
    ]
    c.plugins.prefix = /^!/
    c.plugins.suffix = /$/
  end

end

bot.start