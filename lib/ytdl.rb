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

    def start_caching(url)
      youtubedl_download(url)

    end

    def youtubedl_command
      YTDLCommandFullPath || 'youtube-dl'
    end

    def search_cache(url)
      filematch = url.to_filename('*')
      Dir["#{filematch}.*"]
    end

    def youtubedl_download(url, encode_to_mp3 = true)
      filename = url.to_filename
      return if @download_threads[filename] && @download_threads[filename].alive?
      @download_threads[filename] = Thread.new do
        while true
          command_args = "-o #{filename} #{url.to_s}".split(' ')
          o, e, s = Open3.capture3([youtubedl_command, 'youtube-dl'], command_args)
          break if s.success?
          sleep 0.5
        end
        FFmpeg.encode_mp3(filename) if encode_to_mp3
        @download_threads.delete(filename)
      end

    end

    
    
  end
  
  class FFmpeg
    
    #def self.encode_mp3(filename)
      #command = "ffmpeg -i #{filename} #{filenam}.mp3"
      #Open3.capture3(command)
    #end
    
    # File io pipe may leach eof faster than ffmpeg writing speed
    # so dont return io piping directly mp3 cache file
    def self.create_io_from_partfile(url)
      command = "ffmpeg -loglevel 0 -nostdin -i \"#{url.to_filename}.part\" -f s16le -ar 48000 -ac 2 pipe:1"
      IO.popen(command)
    end

    # filename is some file it contains audio data, mostly downloaded by youtubedl.
    def encode_mp3(filename)
      command = "ffmpeg -loglevel 0 -nostdin -i \"#{filename}\" #{File.basename(filename)}.mp3"
      Open3.capture3(command)

      Dir["#{File.basename(filename)}*"].each do |file|
        next if file == "#{File.basename(filename)}.mp3"
        FileUtils.rm(file)
      end
    end

  end

end
