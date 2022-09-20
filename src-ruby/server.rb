require 'sinatra'
require 'sinatra/base'
require 'aws-sdk-s3'
require 'redcarpet'

set :bind, '0.0.0.0'
set :port, 8080

def get_file(key)

  puts key

  @s3_client = Aws::S3::Client.new(region: 'us-west-2')
  @presigner = Aws::S3::Presigner.new(client: @s3_client)
  @bucket = "uc3-s3-stg"

  url, headers = @presigner.presigned_request(
    :get_object, bucket: @bucket, key: key
  )
  if url
    puts "hello #{url}"
    response.headers['Location'] = url
    status 303
    "success: redirecting"
  else
    status 404
    "#{key} not found"
  end

end

get '/image/*' do
  image = params['splat'][0]
  if image =~ %r[^\d\d\d\d]
    redirect "http://uc3-mrtdocker01x2-dev.cdlib.org:8097/image/#{image.gsub(" ", "%20")}"
  else
    status 403
    "invalid image name"
  end
end

#get '/mods/*' do
#  mods = params['splat'][0]
#  get_file("mods/#{mods}")
#end

get "/output/*.md" do
  f = "output/#{params['splat'][0]}.md"
  renderer = Redcarpet::Render::HTML.new
  markdown = Redcarpet::Markdown.new(renderer, {tables: true})
  markdown.render(File.open(f).read)
end

get "/output/*" do
    send_file "output/#{params['splat'][0]}"
end

get "/" do
  redirect "/output/index.md"
end

get "/erc/*" do
    content_type 'text'
    k = params['splat'][0]
    p = k.split(".")[0]
    send_file "/mrt/output/#{p}/#{k}.erc"
end

get "/checkm/*" do
    content_type 'text'
    k = params['splat'][0]
    p = k.split(".")[0]
    send_file "/mrt/output/#{p}/#{k}.checkm"
end

get "/mods/*" do
    content_type 'application/xml'
    k = params['splat'][0].gsub(".", "_")
    send_file "/mrt/mods/palmu_mods/mods/#{k}.xml"
end
