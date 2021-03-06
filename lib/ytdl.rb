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

    end
    
    
    def download(url)
      url = URL.parse(url)


      
    end
    
    alias_method :dl, :download
    
  end

  # receive command and return audio data IO
  class Executer

    #             @check whether mp4 available
    # Youtube-dl -> videofile.mp4.part -> ffmpeg -> file -> play_io
    #                                    |          ^
    #                                    v          | not EOF
    #                                    wait_th -> till th.join

    SQLite3DBFile = File.join(CacheDirectory, 'index.db')

    'create index.db and initialize' unless FileTest.exist?(SQLite3DBFile)
    #YTDLCommandFullPath = nil

    def initialize
      @db = SQLite3::Database.new(SQLite3DBFile)
      # filename => thread
      @download_threads = {}
    end
    
    # @param src_url is parsed url object
    # return IO
    def get_audio_io(src_url, force_cache = true)
      # if @download_threads[src_url.to_filename]
      Dir.chdir(CacheDirectory) do
        # search cache first
        files = search_cache(src_url)

        # using cache
        if files.find{|file| File.extname(file) == '.mp3'}
          raise # cache found
        end

        # downloading process
        priority_list = ['mp3', 'm4a', 'mp4']
        fmt_list = available_formats(src_url)
        res_fmt = priority_list.find{|fmt| fmt_list.include?(fmt)} if fmt_list

        p src_url, res_fmt
        # make cache data
        start_caching(src_url, res_fmt) #if res_fmt

        # mp* not abailable
        return create_direct_io(src_url) unless res_fmt
      
        # create io from cache part file
        FFmpeg.create_io_from_partfile(src_url, res_fmt)
      end
      
    end

    # note: most of private methods should be called in cache directory
    private

    # return IO
    def download_full_process(url)
      
      
    end

    # -F option parser
    def available_formats(url)
      command = "youtube-dl -F #{url.to_s}"
      formats = nil
      IO.popen(command).each do |each_line|
        next formats = [] if each_line[0..10] == 'format code'
        next unless formats
        #p each_line
        fmt = each_line.split(' ')[1]
        formats << fmt unless formats.include?(fmt)
      end
      p formats
      formats
    end

    # url => encoded_io
    def create_direct_io(url)
      command = "youtube-dl -f mp4 -o - #{url.to_s} | ffmpeg -loglevel 0 -i - -f s16le -ar 48000 -ac 2 pipe:1"
      IO.popen(command)
    end

    # start caching process
    # url is respondable for #to_filename
    def start_caching(url, ext)
      basename = url.to_filename
      @download_threads[basename] = Thread.new do
        Dir.chdir(CacheDirectory)
        #Thread.current.kill if @download_threads[basename] && @download_threads[basename].alive?
        p basename
        # download via youtubedl
        dl_filename = youtubedl_download(url, basename, ext)
        
        # cache audio data as mp3
        ffmpeg_encode_mp3(dl_filename)
        
        # remove files other than mp3 file
        cleanup(basename)
      
        # remove this thread from download thread list
        @download_threads.delete(basename)
      end# unless @download_threads[basename] && @download_threads[basename].alive?
    end

    # deprecated
    def youtubedl_command
      YTDLCommandFullPath || 'youtube-dl'
    end

    # search files generated by linking url
    def search_cache(url)
      filematch = url.to_filename(nil)
      Dir[filematch]
    end

    def youtubedl_download(url, basename, ext)
      basename = url.to_filename unless basename
      basename = "#{basename}.#{ext}" if ext
      filename = nil
      command = "youtube-dl -f #{ext} -o #{basename} #{url.to_s}"
      p "youtube-dl -o #{basename} #{url.to_s}"
      while true
        p command
        o, e, s = Open3.capture3(command)
        md = nil

        o.split("\n").find do |line|
          p line
          # already downloaded
          md = line.match(/\[download\] (.+) has already been downloaded/)
          next true if md
          # get filename
          md = line.match(/\[download\] Destination: (.+)/)
        end unless filename

        filename = md[1] if md
        # may identify 403 or another error...
        break if s.success?
        sleep 0.5
      end
      p filename
      filename
    end
    
    # FFmpeg command wrapper
    def ffmpeg_encode_mp3(filename)
      FFmpeg.encode_mp3(filename)# if encode_to_mp3
    end

    def cleanup(filename)
      # clear files other than mp3
      Dir["#{File.basename(filename)}*"].each do |file|
        next if File.extname(file) == '.mp3'
        FileUtils.rm(file)
      end
    end
    
  end
  
  class FFmpeg
    
    #def self.encode_mp3(filename)
      #command = "ffmpeg -i #{filename} #{filename}.mp3"
      #Open3.capture3(command)
    #end
    
    # File io pipe may leach eof faster than ffmpeg writing speed
    # so dont return io piping directly mp3 cache file
    def self.create_io_from_partfile(url, ext = 'mp4')
      command = "ffmpeg -loglevel 0 -nostdin -i \"#{url.to_filename(ext)}.part\" -f s16le -ar 48000 -ac 2 pipe:1"
      IO.popen(command)
    end

    # filename is some file it contains audio data, mostly downloaded by youtubedl.
    def self.encode_mp3(filename)
      command = "ffmpeg -nostdin -y -i \"#{filename}\" \"#{File.basename(filename, '.*')}.mp3\""
      p command
      Open3.capture3(command)
    end


  end

end
