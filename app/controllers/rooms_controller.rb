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
    @room_ht = JSON.parse(db.get(room_id))
    pl_keys = @room_ht["players"]
    @players = Array.new
    db.select(0)
    pl_keys.each do |pl|
      @players.push(db.get(pl))
    end
    #render text: "#{@room.to_json}"
  end

  # GET /rooms/new
  # GET /rooms/new.json
  def new
    db = Redis.new
    db.select(2)
    keys = db.keys
    #@maps = Array.new(keys.length)
    @maps = Array.new
    len = keys.length - 1
    for i in 0..len
      map_hash = JSON.parse(db[keys[i]])
      #@maps[i] = [map_hash["name"], map_hash["map_id"]]
      @maps.push([map_hash["name"], map_hash["map_id"]])
    end

    #render 'new'
  end

  # GET /rooms/1/edit
  def edit
  end

  # POST /rooms
  # POST /rooms.json
  def create
    db = Redis.new
    # Select ROOM table (1)
    db.select(1)
    room_id = db.keys.map(&:to_i).max + 1

    room_ht = Hash.new {|h,k| h[k]=[]}
    room_ht["room_id"] = room_id
    room_ht["description"] = params[:description]
    room_ht["max"] = params[:max]
    room_ht["map_id"] = params[:map_id]
    room_ht["players"] = [current_user.id.to_s]
    room_ht["admin_id"] = current_user.id.to_s

    db[room_id] = room_ht.to_json

    redirect_to rooms_path
  end

  # PUT /rooms/1
  # PUT /rooms/1.json
  def update
    cur_room_id = params[:id]
    db = Redis.new

    db.select(1)
    r_ht = JSON.parse(db[cur_room_id])
    players = r_ht["players"]

    if params[:purpose] == "join"
      # Fill room
      db.select(1)
      r_ht["players"] = players.push(current_user.id.to_s)
      db[cur_room_id] = r_ht.to_json

      # Fill users parameters with appropriate values
      db.select(0)
      player_ht = JSON.parse(db.get(current_user.id))
      player_ht["room_id"] = cur_room_id
      player_ht["color"] = "color"
      player_ht["bike_num"] = "BIKE_NUM"
      db[current_user.id] = player_ht.to_json
    else
      # Refresh player
      db.select(0)
      player_ht = JSON.parse(db.get(current_user.id))
      player_ht["room_id"] = nil
      player_ht["color"] = "NO color"
      player_ht["bike_num"] = "NO bike"
      db[current_user.id] = player_ht.to_json

      # Refresh room
      db.select(1)
      players.delete(current_user.id.to_s)
      r_ht["players"] = players
      db[cur_room_id] = r_ht.to_json
    end

    redirect_to room_path(cur_room_id)
  end

  # DELETE /rooms/1
  # DELETE /rooms/1.json
  def destroy
    render text: "Deleted room with " + params[:id] + " id number"
  end

  def join
    
  end

end
