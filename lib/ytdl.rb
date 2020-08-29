require 'sqlite3'
require 'open3'


module YoutubeDL

  CommandPath = nil

  # set cache dir
  CacheDirectory = File.join(Dir.pwd, 'cache')

  # download client
  class Client #< Discordrb::Commamds::CommandBot
    
    # download client constractor
    def initialize()
      # filename => thread
      @download_threads = {}
    end
    
    
    def download(url)
      url = URL.parse(url)


      
    end
    
    alias_method :dl, :download
    
  end

  # receive command and return audio data IO
  class Execute

    # Youtube-dl -> videofile.part -> ffmpeg -> file -> play_io
    #                                 |          ^
    #                                 v          | not EOF
    #                                 wait_th -> till th.join

    SQLite3DBFile = File.join(CacheDirectory, 'index.db')

    'create index.db and initialize' unless FileTest.exist?(SQLite3DBFile)
    #YTDLCommandFullPath = nil

    def initialize
      @db = SQLite3::Database.new(SQLite3DBFile)
    end
    
    # @param src_url is parsed url object
    # return IO
    def download_audio(src_url, force_cache = true)
      # if @download_threads[src_url.to_filename]
      Dir.chdir(CacheDirectory) do
        files = search_cache(src_url)

        files.empty?



        


      end
      
    end

    private

    # return IO
    def download_full_process(url)
      
      
    end

    def restore_process

    end

    def youtubedl_command
      YTDLCommandFullPath || 'youtube-dl'
    end

    def search_cache(url)
      filematch = url.to_filename('*')
      Dir["#{filematch}.*"]
    end

    def youtubedl_download(url)
      filename = url.to_filename
      return if @download_threads[filename] && @download_threads[filename].alive?
      @download_threads[filename] = Thread.new do
        while true
          command_args = "-o #{filename} #{url.to_s}".split(' ')
          o, e, s = Open3.capture3([youtubedl_command, 'youtube-dl'], command_args)
          break if s.success?
          sleep 0.5
        end
        @download_threads.delete(filename)
      end

    end

    
    
  end
  
  class FFmpeg
    
    def self.to_mp3(filename)
      
    end
    
    # File io pipe may leach eof faster than ffmpeg writing speed
    def self.create_io_from_partfile(url)
      command = "ffmpeg -i #{url.to_filename}.part - -"
      IO.popen(command)
    end

  end

end
