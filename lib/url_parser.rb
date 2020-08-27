require 'digest'

module YoutubeDL

  module URL
    # init constants
    YOUTUBE_IDENTIFIER = :youtube.freeze
    NICONICO_IDENTIFITER = :niconico.freeze
    RAWDATA_IDENTIFIER = :url.freeze

    # URL parser of YoutubeDL
    def self.parse(original_url)
      # call URI.parse
      uri = URI.parse(original_url)

      case uri.hostname

      # in case of youtube, uri will be exchanged into https://youtu.be/#{id}
      when '(www.)?youtube.com'
        # in case of https://www.youtube.com/watch?v=#{id}
        # without www domain redirects to www.youtube.com
        query = URI.decode_www_form(uri.query)
        id = query['v']

        uri = URI.parse(youtube_url(id))
        uri = URL::Generic.new(*parse_arr(uri), original_url: original_url, service: YOUTUBE_IDENTIFIER)


      when 'youtu.be'
        # in case of https://youtu.be/#{id}
        id = uri.path.chomp('/').delete_prefix('/')

        uri = URI.parse(youtube_url(id))
        uri = URL::Generic.new(*parse_arr(uri), id: id, original_url: original_url, service: YOUTUBE_IDENTIFIER)


      when /(www.)?nicovideo\.jp/, 'nico.ms'
        # nico.ms and www.nicovideo.jp redirects www.nicovideo.jp
        id = uri.path.chomp('/').split('/').last[2..-1]

        uri = URI.parse(niconico_url(id))
        uri = URL::Generic.new(*parse_arr(uri), id: id, original_url: original_url, service: NICONICO_IDENTIFITER)


      else
        # any audio file resources of url
        id = Digest::MD5.hexdigest(original_url)

        uri = URL::Generic.new(*parse_arr(uri), id: id, original_url: original_url, service: RAWDATA_IDENTIFIER)

      end

      uri
    end

    # avoid overriding build method in URI class
    def self.build_url(service, id)
      case service
      when YOUTUBE_IDENTIFIER
        uri = parse(youtube_url(id))
      when NICONICO_IDENTIFITER
        uri = parse(niconico_url(id))
      when RAWDATA_IDENTIFIER
        # id should be url
        uri = parse(id)
      else
        raise 'unknown service was specified'
      end
      uri
    end


    # restore original url data
    # returns nil if restore failed
    def self.build_from_filename(filename, original_url = nil)
      md = filename.match(/([a-zA-Z0-9]+)-(.+)\.(.+)/)
      raise 'not matched' unless md
      service, id, ext = md.captures
      service = service.to_sym

      case service
      when YOUTUBE_IDENTIFIER
        uri = parse(youtube_url(id))
      when NICONICO_IDENTIFITER
        uri = parse(niconico_url(id))
      when RAWDATA_IDENTIFIER
        # id is hash value of original url string
        return nil unless id == Digest::MD5.hexdigest(original_url)
        uri = parse(original_url)
      else
        return nil
        #raise 'unknown service was specified'
      end
      uri
    end

    private

    # for backward compatibility
    def self.parse_arr(uri)
      # check whether url using default port
      port = {'http' => 80, 'https' => 443}.find{|sc, port| uri.scheme == sc && uri.port == port} ? nil : uri.port
      [uri.scheme, uri.userinfo, uri.host, port, uri.registry, uri.path, uri.opaque, uri.query, uri.fragment]
    end

    # deprecated
    def self.parse_hash(uri)
      {scheme: uri.scheme, userinfo: uri.userinfo, host: uri.host, port: nil, registry: uri.registry, path: uri.path, opaque: uri.opaque, query: uri.query, fragment: uri.fragment}
    end

    # these method works removing unrelated query for downloading
    def self.niconico_url(id)
      "https://nico.ms/sm#{id}"
    end

    def self.youtube_url(id)
      "https://youtu.be/#{id}"
    end


    # URL instance contains video service data
    class Generic < URI::Generic

      attr_reader :service

      def initialize(*arr, **hash)
        #build_elements = [:scheme ,:userinfo, :host, :port, :registry, :path, :opaque, :query, :fragment]
        #super(hash.select{|k| build_elements.include?(k)})
        super(*arr)

        # YoutubeDL original param
        @service, @original_url, @id = hash[:service], hash[:original_url], hash[:id]
      end


      # cache filename => service-id.mp3
      # ex: niconico-12345.mp3, youtube-ABCDE.mp3, url-#{url-hash}
      # ~~ filename should not contain '-' ather than separator of service and id ~~
      def to_filename(ext = 'mp3')
        "#{@service.to_s}-#{@id.to_s}.#{ext}"
      end

    end

  end

end