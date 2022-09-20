require 'sinatra'
require 'sinatra/base'
require 'aws-sdk-s3'
require 'redcarpet'
require 'down'

set :bind, '0.0.0.0'
set :port, 8080

def get_file(key)

  puts "Key: #{key}"

  @s3_client = Aws::S3::Client.new(region: 'us-west-2')
  
  @bucket = "uc3-s3-stg"

  resp = @s3_client.get_object({
    bucket: @bucket, 
    key: key, 
  })

  if resp
    content_type resp.content_type
    resp.body.read
  else
    status 404
    "#{key} not found"
  end

end

get '/image/*' do
  image = params['splat'][0]
  if image =~ %r[^\d\d\d\d]
    get_file(image)
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

get "/inventory" do
    send_file "/mrt/inventory/inventory.txt"
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
