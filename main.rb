require 'sinatra'
require 'httparty'
require 'sinatra/json'

AGENCIES = nil

get '/' do
  @action = "http://agile-plains-1962.herokuapp.com/api/v1/query/gremlin"
  if AGENCIES
    @agencies = AGENCIES
  else
    @agencies = HTTParty.post(@action, {body: "g.V().Out('name').All()" })
    @agencies = JSON.parse(@agencies.body)["result"]
    AGENCIES = @agencies = @agencies.map{|agent| agent["id"].gsub(/\s/, '_')}.sort
  end
  if params[:agent] && params[:relationship1]
    query = "g.V().Has('name', '#{params[:agent].gsub(/_/, ' ')}').Out('#{params[:relationship1]}')"
    query += ".Out('#{params[:relationship2]}')" if params[:relationship2] && !params[:relationship2].empty?
    query += ".Out('#{params[:relationship3]}')" if params[:relationship3] && !params[:relationship3].empty?
    query += ".Out(['name', 'start date', 'end date']).All()"
    logger.info query
    # fetch output
    @output = HTTParty.post(@action, {body: query})
    @output = JSON.parse(@output.body)["result"]
    logger.info @output.inspect
  end
  @relationships = %w(precedes subordinates)
  erb :index
end

get '/.json' do
  @action = "http://agile-plains-1962.herokuapp.com/api/v1/query/gremlin"
  @graph = "http://agile-plains-1962.herokuapp.com/api/v1/shape/gremlin"
  if params[:agent] && params[:relationship1]
    query = "g.V().Has('name', '#{params[:agent].gsub(/_/, ' ')}').Out('#{params[:relationship1]}')"
    query += ".Out('#{params[:relationship2]}')" if params[:relationship2] && !params[:relationship2].empty?
    query += ".Out('#{params[:relationship3]}')" if params[:relationship3] && !params[:relationship3].empty?
    if params[:relationship3] && !params[:relationship3].empty?
      target_node = 8
    elsif params[:relationship2] && !params[:relationship2].empty?
      target_node = 6
    else
      target_node = 4
    end
    query = query + ".Out('name').GetLimit(5)"
    logger.info query
    @output = HTTParty.post(@action, {body: query})
    @output = JSON.parse(@output.body)["result"]
    logger.info @output.inspect
    names = []
    @output.each{|o| names << o["id"]}
    names.uniq!
    @graph = HTTParty.post(@graph, {body: query})
    @graph = JSON.parse(@graph.body)
    logger.info @graph.inspect
    @graph["nodes"].each_with_index do |node, index|
      if index == target_node && node["is_link_node"] == false
        node["values"] = names
      else
        next
      end
    end
    json @graph
  else
    "No result"
  end
end

helpers do
  def h(text)
    Rack::Utils.escape_html(text)
  end
end
