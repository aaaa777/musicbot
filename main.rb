require 'bundler/setup'

require 'discordrb'
require 'pg'
require 'lib/ytdl-wrapper'

prefix_caller = Proc.new{|message|
    server_id = message.server.id
    message_content = message.content
    server_attributes[server_id](message_content)
}

server_attributes = {
    #server_id => {
    #   prefix: []
    #}
}

bot = Discordrb::Commands::CommandBot.new(
    token: ENV['TOKEN'],
    prefix: ['/'],#prefix_caller,
    help_command: false,
    ignore_bots: true
)

bot.command([:cn, :con, :connect]) do |event|
    user = event.author
    vc_channel = user.voice_channel
    return 'you\'re not in any voice channel!' unless vc_channel
    return 'I cant see the voice channel you are in' event.server.channels.include(vc_channel)

    bot.voice_connect(vc_channel)

end


bot.run