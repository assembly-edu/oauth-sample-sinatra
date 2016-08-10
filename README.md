Assembly Sinatra OAuth Example
==============================

Hi there. This repository is a really simple example of how to build a basic OAuth flow. The Assembly Platform uses OAuth tokens to protect school data and your application will, therefore, need to implement the Assembly Platform OAuth flow in order to let schools see to which of their data your application is requesting access.


We've created this repo because first time users of OAuth are often unsure about how to implement the necessary steps and browser testing really isn't the best way to kick the tyres on the Assembly Platform's OAuth because we need to call your appliction back once the school (or, in this case, probably your test school) has approved your application for access to their data.

Up and Running
--------------

To use this example you'll need a recent Ruby installation (we used v2.3.1 for this) and you'll need bundler. Before you get started on this you'll need to create an application on the Assembly Platform. To do that read [this](http://help.assembly.education/article/38-signing-up-to-the-platform).

Once you've done that you should have an application ID and secret that you can substitute in the commands below.

	bundle install
	APP_ID=<your_app_token_here> APP_SECRET=<your_app_secret_here> ruby oauth-sample.rb

Now you can visit the Sinatra app by going to [http://localhost:4567/](http://localhost:4567/) in your browser.

The OAuth Flow
--------------

When you hit [the example app](http://localhost:4567/) in your browser the following things will happen:

* **Immediately re-direct you to the Assembly Platform Sandbox** _which is caused by this code in the example app:_

```ruby
get '/' do
	state  = (0...50).map { ('a'..'z').to_a[rand(26)] }.join
	scopes = %w(students teaching_groups staff_members).join('+')
	redirect to("https://platform-sandbox.assembly.education/oauth/authorize?redirect_uri=#{CALLBACK}&client_id=#{APP_ID}&scope=#{scopes}&state=#{state}")
end
```

In this code snippet first generates a random string which you should send along with your request to protect against CSRF. Then we enumerates the scopes that your application is asking for. Finally, we redirect the browser to the Assembly Platform. *This part of the flow would normally be completed by the school's data manager or such a responsible person* so, in order to test, you'll need to login to as your test school.

* **Once you've logged in as the school (or, in production, someone at the school has logged in)** _The Assembly Platform will call your app back:_

```ruby
get '/auth/assembly/callback' do
	auth_code = params['code']
	csrf_code = params['state']
	...
end
```

If the school has decided to allow it access to their data, the Assembly Platform will call your application back supplying a `code` that you may then exchange for a [JWT token](https://jwt.io/) and a refresh token that is allowed to access the scopes of data that your app requested in the first step. The sample Sinatra app does that, very simple, like this:

```ruby
...
response = RestClient.post "https://platform-sandbox.assembly.education/oauth/token?grant_type=authorization_code&code=#{auth_code}&redirect_uri=#{CALLBACK}", {},
	{ Accept: 'application/json', Authorization: basic_auth_header(APP_ID, APP_SECRET) }
...	
```

The JWT token and other information about the school will be printed out in your brower. In your real app you'll need to store this information and keep it secure. The response sent back to you by the Assembly Platform will look something like this:

```
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJuYmYiOjE0NzA4NTQ4MDMsImlzcyI6Imh0dHBzOi8vcGxhdGZvcm0uYXNzZW1ibHkuZWR1Y2F0aW9uIiwiaWF0IjoxNDcwODU0ODAzLCJsZXZlbCI6InNjaG9vbCIsInNjb3BlcyI6WyJzY2hvb2wiLCJzdGFmZl9tZW1iZXJzIiwic3R1ZGVudHMiLCJ0ZWFjaGluZ19ncm91cHMiXSwiYXBwX2lkIjoyLCJzY2hvb2xfaWQiOjEsImV4cCI6MTQ3MzQ0NjgwM30.hXI8uJAtKLX8eiP0LAxw8IgOpACkuO36m24Zq0LBqUE",
  "expires_in": 2592000,
  "level": "school",
  "refresh_token": "z39i0btW1JMcpBBTMxYKa3YesxoutywM4aBzMFpAZl8",
  "school_id": 1,
  "token_type": "bearer"
}
```

Clearly this is a grossly over simplified application that is purely intented to help you understand OAuth and the OAuth flow that is necessary to interact with the Assembly Platform and to keep school data safe and secure.


