module YoutubeDL

  module URL
    #extend URI

    # URL parser of YoutubeDL
    def self.parse(original_uri)
      # call URI.parse
      uri = URI.parse(original_uri)
      
      case uri.hostname
      # in case of youtube, uri will be exchanged into https://youtu.be/#{id}
      when '(www.)?youtube.com'
        # in case of https://www.youtube.com/watch?v=#{id}
        # without www domain redirects to www.youtube.com
        query = URI.decode_www_form(uri.query)
        id = query['v']

        uri = URI.parse(youtube_url(id))
        uri = URL::Generic.new(*parse_arr(uri))
        #service = :youtube
        #uri = super(youtube_url(@id))
      when 'youtu.be'
        # in case of https://youtu.be/#{id}
        id = uri.path.chomp('/').delete_prefix('/')

        uri = URI.parse(youtube_url(id))
        uri = URL::Generic.new(*parse_arr(uri))
        #service = :youtube
      when /(www.)?nicovideo\.jp/, 'nico.ms'
        # nico.ms and www.nicovideo.jp redirects www.nicovideo.jp
        id = uri.path.chomp('/').split('/').last[2..-1]#.delete_prefix('sm')

        uri = URI.parse(niconico_url('sm' + id))
        #p parse_hash(uri)
        uri = URL::Generic.new(*parse_arr(uri))
        service = :nicovideo
      else
        #@id = nil
        service = :url
      end

      uri
    end

    private

    # for backward compatibility
    def self.parse_arr(uri)
      [uri.scheme, uri.userinfo, uri.host, uri.port, uri.registry, uri.path, uri.opaque, uri.query, uri.fragment]
    end

    # deprecated
    def self.parse_hash(uri)
      {scheme: uri.scheme, userinfo: uri.userinfo, host: uri.host, port: uri.port, registry: uri.registry, path: uri.path, opaque: uri.opaque, query: uri.query, fragment: uri.fragment}
    end

    # these method works removing unrelated query for downloading
    def self.niconico_url(id)
      "https://nico.ms/#{id}"
    end
    
    def self.youtube_url(id)
      "https://youtu.be/#{id}"
    end
      

    # URL instance contains video service data
    class Generic < URI::Generic
      
      def initialize(*arr, **hash)
        if hash.empty?
          super(*arr)
        else
          super(**hash)
        end
      end
      
      # avoid overriding build method in URI class
      def build_url(service, id)
        case service
        when :youtube, :yt
          uri = parse(youtube_url(id))
        when :nicovideo, :nico
          uri = parse(niconico_url(id))
        else
          raise 'unknown service was specified'
        end
      end
      

      
      def service_to_sym(service)
        case service
        when 'youtu.be', :youtube, :yt
          :youtube
        when 'niconico.jp', :nicovideo, :nico
          :nicovideo
        else
          self.to_s
        end
      end
      
      def to_cache_name
        
      end
      
      def to_download_format
        service_type = service
        
        
      end
      
    end
  end
  
  
end