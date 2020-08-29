require 'discordrb'


class MusicBot < Discordrb::Commands::CommandBot
  def initialize()
    super(
      token: ENV['TOKEN'],
      prefix: 'm@'# default prefix. it will be selectable by Proc
    )
    @downloader = YoutubeDL::Client.new
  end

  def start
    run
  end

  private

  def add_command(sym, **options, &block)
    command(sym, **options, &block)
  end

  def play_command(key)
    command(key, private: false) do |event, *args|
      url = args.join(' ')
      begin
        url = YoutubeDL::URL.parse(url)
      rescue => exception
        return 'invalid url!'
      end
      audio_io = @downloader.download_audio(url)
      
    end
  end
end