require 'base64'
require 'erb'
require 'json'
require 'rest-client'
require 'sinatra'

include ERB::Util

use Rack::Session::Pool, :expire_after => 10000

APP_ID       = ENV['APP_ID']
APP_SECRET   = ENV['APP_SECRET']
CALLBACK     = url_encode('http://localhost:4567/auth/assembly/callback')
PLATFORM_URI = 'https://platform-sandbox.assembly.education/'

get '/' do
  # You should implement your own logic to check whether a school has paid for your app before allowing them to authorize
  # because Assembly charge on a per-authorization basis.
  redirect to('/unpaid') if params['school_urn'] == 'XXXXXX'
  session['school_urn'] = params['school_urn']
  erb :index
end

get '/auth_me' do
  state  = (0...50).map { ('a'..'z').to_a[rand(26)] }.join
  scopes = %w(students teaching_groups).join('+')
  redirect to("#{PLATFORM_URI}/oauth/authorize?urn=#{session['school_urn']}&redirect_uri=#{CALLBACK}&client_id=#{APP_ID}&scope=#{scopes}&state=#{state}")
end

get '/auth/assembly/callback' do
  auth_code = params['code']  # This code may be exchanged for an access and refresh token scoped for only the authorizing school.
  csrf_code = params['state'] # In your real app you should verify this code matches what you sent.
  error     = params['error']
  error_msg = params['error_description']

  if error
    erb :rejected, locals: { error: error, message: error_msg }
  else
    response = RestClient.post "#{PLATFORM_URI}/oauth/token?grant_type=authorization_code&code=#{auth_code}&redirect_uri=#{CALLBACK}", {},
      { Accept: 'application/json', Authorization: basic_auth_header(APP_ID, APP_SECRET) }

    json = JSON.parse(response.body)
    erb :authed, locals: { json: json }
  end
end

get '/unpaid' do
  erb :unpaid
end

def basic_auth_header(id, secret)
  'Basic ' + Base64.strict_encode64("#{id}:#{secret}")
end



