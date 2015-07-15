#
require 'rubygems'
require 'sinatra/base'
require 'webrick'
require 'webrick/https'
require 'openssl'

require "net/https"
require "uri"


webrick_options = {
        :Port               => 8443,
        :Logger             => WEBrick::Log::new($stderr, WEBrick::Log::DEBUG),
        :DocumentRoot       => "./",
        :SSLEnable          => true,
        :SSLVerifyClient    => OpenSSL::SSL::VERIFY_NONE,
        :SSLCertificate     => OpenSSL::X509::Certificate.new(
          File.open("server.crt").read
          ),
        :SSLPrivateKey      => OpenSSL::PKey::RSA.new(
          File.open("server.key").read
          ),
        :SSLCertName        => [ [ "CN",WEBrick::Utils::getservername ] ],
}

class SSLServer  < Sinatra::Base
  get "/oauth" do
    p "GET: #{params.inspect}"
    p ""
    res = stuff params
    p "#{res.code}: #{res.body}"
    p ""
    return "OK"
  end

  post /(.*)/ do
    p "POST: #{params}"
    p ""
    res = stuff params
    p "#{res.code}: #{res.body}"
    p ""
    return "OK"
  end

  def stuff params
    oauth_params = {
          'client_id' => 'r6er8dl7ijhc5axoym9n9cb2egugiuc',
          'client_secret' => 'o36m87ohb4cjlxuw9c91ge1rq4l65j4',
          'code' => params['code'],
          'scope'=> params['scope'],
          'grant_type'=> 'authorization_code',
          'redirect_uri'=> 'https://76.73.176.20:8443/oauth',
          'context' => params['context']
      }

    uri = URI.parse("https://login.bigcommerce.com/oauth2/token")
    http = Net::HTTP.new(uri.host, uri.port)

    http.use_ssl = true
    req = Net::HTTP::Post.new(uri.request_uri)
    http.set_debug_output($stdout)
    req.set_form_data(oauth_params)
    response = http.request(req)
    return response
  end
end


server = ::Rack::Handler::WEBrick

trap(:INT) do
  if server.respond_to?(:shutdown)
    server.shutdown
  else
    exit
  end
end

server.run SSLServer, webrick_options
