require 'base64'
require 'erb'
require 'json'
require 'rest-client'
require 'sinatra'

include ERB::Util

APP_ID     = ENV['APP_ID']
APP_SECRET = ENV['APP_SECRET']
CALLBACK   = url_encode('http://localhost:4567/auth/assembly/callback')

get '/' do 
	erb :index	
end

get '/auth_me' do
	state  = (0...50).map { ('a'..'z').to_a[rand(26)] }.join
	scopes = %w(students teaching_groups).join('+')
	redirect to("https://platform-sandbox.assembly.education/oauth/authorize?redirect_uri=#{CALLBACK}&client_id=#{APP_ID}&scope=#{scopes}&state=#{state}")
end

get '/auth/assembly/callback' do
  logger.info "Callback Params: #{params}"

	auth_code = params['code']    # This code may be exchanged for an access and refresh token scoped for only the authorising school.
	csrf_code = params['state']   # In your real app you should verify this code matches what you sent.
  error     = params['error']
	error_msg = params['error_description']

  if error
		erb :rejected, locals: { error: error, message: error_msg }
  else
		response = RestClient.post "https://platform-sandbox.assembly.education/oauth/token?grant_type=authorization_code&code=#{auth_code}&redirect_uri=#{CALLBACK}", {},
			{ Accept: 'application/json', Authorization: basic_auth_header(APP_ID, APP_SECRET) }

		json = JSON.parse(response.body)
		erb :authed, locals: { json: json }
  end
end

def basic_auth_header(id, secret)
	'Basic ' + Base64.strict_encode64("#{id}:#{secret}")
end



