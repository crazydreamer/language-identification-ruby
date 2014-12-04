#
# Copyright IBM Corp. 2014
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'sinatra'
require 'json'
require 'excon'

configure do
  service_name = "language_identification"

  endpoint = Hash.new

  set :endpoint, "<service_url>"
  set :username, "<service_username>"
  set :password, "<service_password>"

  if ENV.key?("VCAP_SERVICES")
    services = JSON.parse(ENV["VCAP_SERVICES"])
    if !services[service_name].nil?
      credentials = services[service_name].first["credentials"]
      set :endpoint, credentials["url"]
      set :username, credentials["username"]
      set :password, credentials["password"]
    else
      puts "The service #{service_name} is not in the VCAP_SERVICES, did you forget to bind it?"
    end
  end

  # Add a trailing slash, if it's not there
  unless settings.endpoint.end_with?('/')
    settings.endpoint = settings.endpoint + '/'
  end

  puts "endpoint = #{settings.endpoint}"
  puts "username = #{settings.username}"
end

get '/' do
  erb :index
end

post '/' do

  @text = params[:text]
  content = {
      :txt => @text,
      :sid => 'lid-generic',
      :rt => 'json' # the response will be the translated text
  }

  begin
    headers = {
      "Content-Type" => "application/x-www-form-urlencoded",
      "Accept" => "application/json"
    }

    response = Excon.post(settings.endpoint,
      :body => URI.encode_www_form(content),
      :headers => headers,
      :user => settings.username,
      :password => settings.password)

    puts response.body
    STDOUT.flush

    # the service responses with 5-letter ISO language code
    @lang = JSON.load(response.body)['lang']

  rescue Exception => e
    @error = 'Error processing the request, please try again later.'
    puts  e.message
    puts  e.backtrace.join("\n")
  end

  erb :index

end