#app.rb

require "rubygems"
require "sinatra"
require "erb"
require "oauth"
require "oauth/consumer"
require "json" 
require "open-uri"
require "rest_client"
require "cgi"

enable :sessions

unless ENV["500PX_APIKEY"] && ENV["500PX_SECRET"] && ENV["AVIARY_APIKEY"]
  abort("missing env vars: please set 500PX_APIKEY, 500PX_SECRET and AVIARY_APIKEY with your app credentials")
end

before do
  session[:oauth] ||= {}  
  @consumer ||= OAuth::Consumer.new(ENV["500PX_APIKEY"], ENV["500PX_SECRET"], {
  :site => "https://api.500px.com/",
  :request_token_path => "/v1/oauth/request_token",
  :access_token_path  => "/v1/oauth/access_token",
  :authorize_path     => "/v1/oauth/authorize"
  })
  
  if !session[:oauth][:request_token].nil? && !session[:oauth][:request_token_secret].nil?
    @request_token = OAuth::RequestToken.new(@consumer, session[:oauth][:request_token], session[:oauth][:request_token_secret])
  end
  
  if !session[:oauth][:access_token].nil? && !session[:oauth][:access_token_secret].nil?
    @access_token = OAuth::AccessToken.new(@consumer, session[:oauth][:access_token], session[:oauth][:access_token_secret])
  end
end

#simple XOR encrypt/decrypt
ENCRYPTION_KEY = "16"

def base_url
  default_port = (request.scheme == "http") ? 80 : 443
  port = (request.port == default_port) ? "" : ":#{request.port.to_s}"
  "#{request.scheme}://#{request.host}#{port}"
end

class Array
  def xor(key)
    a = dup
    a.length.times { |n| a[n] ^= key[n % key.size] }
    a
  end
end

get "/" do
  if @access_token
  #Get user:
  user_json = @access_token.get("https://api.500px.com/v1/users").body
  user_json_parsed = JSON.parse(user_json)
  user_username = user_json_parsed["user"]["username"]
  #Get photos by current user (username):
  photo_json = @access_token.get("https://api.500px.com/v1/photos?feature=user&username=" + user_username).body
  photo_json_parsed = JSON.parse(photo_json)
  @photo_photos = photo_json_parsed["photos"]

  plaintext_secret = @access_token.secret
  @cipher = plaintext_secret.codepoints.to_a.xor(ENCRYPTION_KEY.codepoints.to_a).inject("") { |s,c| s << c }

  @token = @access_token.token 
  erb :ready
  else
    erb :auth
  end
end

get "/request" do
  callback_url = "#{base_url}/callback"
  @request_token = @consumer.get_request_token(:oauth_callback => callback_url)
  session[:oauth][:request_token] = @request_token.token
  session[:oauth][:request_token_secret] = @request_token.secret
  redirect @request_token.authorize_url
end

get "/callback" do
  @access_token = @request_token.get_access_token :oauth_verifier => params[:oauth_verifier]
  session[:oauth][:access_token] = @access_token.token
  session[:oauth][:access_token_secret] = @access_token.secret
  redirect "/"
end

#url
#hiresurl
#postdata: token$$$secret$$$originalName
post "/save" do
  postDataArray = params[:postdata].split("$$$")
  if (postDataArray.length == 3)
    token = postDataArray[0]
    secret = postDataArray[1].codepoints.to_a.xor(ENCRYPTION_KEY.codepoints.to_a).inject("") { |s,c| s << c }
    #original photo name is postdata
    orig_name = postDataArray[2]
    # get an access token, this is out of session
    new_name = orig_name + " (edited with Aviary)"
    # get file name from URL
    file_name = params[:url].split("/").pop()
    # Retrieve a file object from the image URL
    image_from_web  = open(params[:hiresurl]) {|f| f.read }
    # Write the file to the local filesystem
    Dir.mkdir ENV['TMPDIR'] unless Dir.exists? ENV['TMPDIR'] 
    Dir.chdir(ENV['TMPDIR'])
    File.open(file_name, "w") {|f| f.write(image_from_web) }
    Dir.chdir("../")

    # may need to create this
      @access_token = OAuth::AccessToken.new(@consumer, token, secret)
    # Post to 500px to get our upload token, name will be @new_name
    if @access_token
      upload_json = @access_token.post("https://api.500px.com/v1/photos", :name => new_name).body
      upload_json_parsed = JSON.parse(upload_json)
      upload_key = upload_json_parsed["upload_key"]
      photo_id = upload_json_parsed["photo"]["id"]
      # Now make the post!
      @message = RestClient.post("https://api.500px.com/v1/upload", 
      
        {
          :consumer_key => "W5eYuliuRCuuj8SCBzmM5duZA2hYlIln49bQha2z",
          :access_key => @access_token.token,
          :upload_key => upload_key,
          :photo_id => photo_id,
  #       :file => image_from_web
          :file => File.new("tmp/" + file_name)
        }
      )
      
    end
  end

# erb :save
end

get "/logout" do
  session[:oauth] = {}
  redirect "/"
end
