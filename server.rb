require 'sinatra'
require 'sinatra/reloader'
require 'pg'
require 'pry'

def db_connection
  begin
    connection = PG.connect(dbname: 'movies')

    yield(connection)

  ensure
    connection.close
  end
end

helpers do
  def on_last_page_actors?(page_num)
    page_num < 2672
  end

  def on_last_page_movies?(page_num)
    page_num < 164
  end

  def on_first_page?(page_num)
    page_num == 1
  end
end


get '/' do
  redirect '/movies'
end

get '/movies' do
  if params[:page]
    @page_num = params[:page].to_i
  else
    @page_num = 1
  end

  query = 'SELECT movies.id, movies.title, movies.year, movies.rating, genres.name AS genre, studios.name AS studio
    FROM movies
    JOIN genres ON movies.genre_id = genres.id
    LEFT OUTER JOIN studios ON movies.studio_id = studios.id'

  if params[:order] == 'rating'
    query += " ORDER BY movies.rating"
  elsif params[:order] == 'year'
    query += " ORDER BY movies.year DESC"
  else
    query += " ORDER BY movies.title"
  end

  query += " LIMIT 20 OFFSET $1"

  @movies = db_connection do |conn|
    conn.exec_params(query, [(@page_num - 1) * 20]).to_a
  end

  erb :'movies/index'
end

get '/actors' do
  if params[:page]
    @page_num = params[:page].to_i
  else
    @page_num = 1
  end

  query = 'SELECT actors.name, actors.id FROM actors
  ORDER BY actors.name LIMIT 20 OFFSET $1;'

    db_connection do |conn|
    @actors = conn.exec_params(query, [(@page_num - 1) * 20]).to_a
    end
  erb :'actors/index'
end

get '/movies/:id' do
id = params[:id]

db_connection do |conn|
@movie = conn.exec_params('SELECT movies.title, movies.year, movies.rating, genres.name AS genre, studios.name AS studio, cast_members.character, actors.name as actor, actors.id
FROM movies
LEFT OUTER JOIN cast_members ON movies.id = cast_members.movie_id
LEFT OUTER JOIN actors ON cast_members.actor_id = actors.id
JOIN genres ON movies.genre_id = genres.id
LEFT OUTER JOIN studios ON movies.studio_id = studios.id
WHERE movies.id = $1', [id]).to_a
end

erb :'movies/show'
end

get '/actors/:id' do
  id = params[:id]
  query = 'Select movies.id AS movie_id, cast_members.character, movies.title, actors.name
FROM cast_members
JOIN movies ON movies.id = cast_members.movie_id
JOIN actors ON cast_members.actor_id = actors.id
WHERE cast_members.actor_id = $1;'
db_connection do |conn|
@actor = conn.exec_params(query, [id]).to_a
end
erb :'actors/show'
end
