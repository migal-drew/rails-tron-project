require "redis"
require "json"

class Room
  attr_accessor :id, :users, :state, :num_of_users
  #attr_reader :firm, :model

  def initialize(f, m)
    @users = f
    @state = m
  end
end

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
    @room = db.get(room_id)
    
    render text: "#{@room.to_json}"
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
    room_id = db.keys.max.to_i + 1

    room_ht = Hash.new {|h,k| h[k]=[]}
    room_ht["room_id"] = room_id
    room_ht["description"] = params[:description]
    room_ht["max"] = params[:max]
    room_ht["map_id"] = params[:map_id]
    room_ht["players"] = []
    room_ht["admin_id"] = current_user.id

    db[room_id] = room_ht.to_json

    redirect_to rooms_path
  end

  # PUT /rooms/1
  # PUT /rooms/1.json
  def update
  end

  # DELETE /rooms/1
  # DELETE /rooms/1.json
  def destroy
    render text: "Deleted room with " + params[:id] + " id number"
  end
end
