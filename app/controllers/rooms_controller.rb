require "redis"
require "json"

class RoomsController < ApplicationController
  # GET /rooms
  # GET /rooms.json
  def index
    r = Redis.new
    r.select(1)

    keys = r.keys
    @rooms = Array.new(keys.length)
    len = keys.length - 1
    for i in 0..len
      @rooms[i] = JSON.parse(r[keys[i]])
    end

  end

  # GET /rooms/1
  # GET /rooms/1.json
  def show
    room_id = params[:id]
    db = Redis.new
    db.select(1)
    room = db.get(room_id)
    if !room.nil?
      @room_ht = JSON.parse(room)
      pl_keys = @room_ht["players"]
      @players = Array.new
      db.select(0)
      pl_keys.each do |pl|
        @players.push(db.get(pl))
      end
    else
      redirect_to rooms_path
    end
  end

  # GET /rooms/new
  # GET /rooms/new.json
  def new
    db = Redis.new
    db.select(2)
    keys = db.keys
    @maps = Array.new
    len = keys.length - 1
    for i in 0..len
      map_hash = JSON.parse(db[keys[i]])
      @maps.push([map_hash["name"], map_hash["map_id"]])
    end

    #render 'new'
  end

  # GET /rooms/1/edit
  def edit
    render 'show'
  end

  # POST /rooms
  # POST /rooms.json
  def create
    if !params[:description].empty?
      db = Redis.new
      # Select ROOM table (1)
      db.select(1)
      room_id = db.keys.max
      if room_id.nil?
        room_id = 1
      else
        room_id = room_id.to_i + 1
      end

      room_ht = Hash.new {|h,k| h[k]=[]}
      room_ht["room_id"] = room_id
      room_ht["description"] = params[:description]
      #room_ht["max"] = params[:max]
      room_ht["map_id"] = params[:map_id]
      room_ht["players"] = [current_user.id]
      room_ht["admin_id"] = current_user.id

      db[room_id] = room_ht.to_json

      db.select(0)
      player_ht = JSON.parse(db[current_user.id])
      player_ht["bike_num"] = 0
      player_ht["room_id"] = room_id
      db[current_user.id] = player_ht.to_json

      redirect_to rooms_path
    else
      redirect_to '/rooms/new', :notice => 'Set description!'
    end
  end

  # PUT /rooms/1
  # PUT /rooms/1.json
  def update
    cur_room_id = params[:id]
    db = Redis.new

    db.select(1)
    r_ht = JSON.parse(db.get(cur_room_id))
    db.select(0)
    player_ht = JSON.parse(db.get(current_user.id))

    players = r_ht["players"]

    if params[:purpose] == "join"
      #Refresh player
      player_ht["room_id"] = cur_room_id

      bikes = get_players_bikes_nums(players)
      player_ht["bike_num"] = bikes.max + 1
      db.select(0)
      db[current_user.id] = player_ht.to_json

      #Refresh room
      db.select(1)
      r_ht["players"] = players.push(current_user.id)
      db[cur_room_id] = r_ht.to_json
    else
      # Refresh player
      db.select(0)
      player_ht["room_id"] = nil
      player_ht["color"] = "NO color"
      player_ht["bike_num"] = "NO bike"
      db[current_user.id] = player_ht.to_json

      #Refresh room
      db.select(1)
      r_ht["players"].delete(current_user.id)
      db[cur_room_id] = r_ht.to_json
    end


    redirect_to room_path(cur_room_id)
  end

  # DELETE /rooms/1
  # DELETE /rooms/1.json
  def destroy
    # Only admin can delete rooms!
    db = Redis.new
    db.select(1)
    db.del(params[:id])
    redirect_to rooms_path
  end

# --------------------------------------------------------------------
def get_players_bikes_nums(players_ids)
    db = Redis.new
    db.select(0)
    bikes = Array.new
    for i in 0..players_ids.length - 1
      cur_player = JSON.parse(db.get(players_ids[i]))
      bikes.push(cur_player["bike_num"])
    end
    return bikes
end

end
