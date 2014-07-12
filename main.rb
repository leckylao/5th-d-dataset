require 'sinatra'
require 'httparty'

AGENCIES = nil

get '/' do
  @action = "http://agile-plains-1962.herokuapp.com/api/v1/query/gremlin"
  if AGENCIES
    @agencies = AGENCIES
  else
    @agencies = HTTParty.post(@action, {body: "g.V().Out('name').All()" })
    AGENCIES = @agencies
  end
  @agencies = JSON.parse(@agencies.body)["result"]
  if params[:agent] && params[:relationship1]
    query = "g.V().Has('name', '#{params[:agent].gsub(/_/, ' ')}').Out('#{params[:relationship1]}')"
    query += ".Out('#{params[:relationship2]}')" if params[:relationship2] && !params[:relationship2].empty?
    query += ".Out('#{params[:relationship3]}')" if params[:relationship3] && !params[:relationship3].empty?
    query += ".Out(['name', 'start date', 'end date']).All()"
    logger.info query
    @output = HTTParty.post(@action, {body: query})
    @output = JSON.parse(@output.body)["result"]
    logger.info @output.inspect
  end
  @relationships = %w(precedes subordinates)
  erb :index
end

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end
end
