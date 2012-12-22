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
      @rooms[i] = r[keys[i]]
    end

  end

  # GET /rooms/1
  # GET /rooms/1.json
  def show
    #render text: params[:id]
    #r = Redis.new
    #r.set(1, '{"firm": "Aidu", "model": "4343a"}')
    #str = r.get(1)
    #hash = JSON.parse(str)
    #render text: hash

    #@mycar = Car.new('BMW', '100500_KickAss')
    #s = ActiveSupport::JSON.encode(mycar)

    #c = from_json(s)
    #render text: mycar.to_json()
  end

  # GET /rooms/new
  # GET /rooms/new.json
  def new
  end

  # GET /rooms/1/edit
  def edit
  end

  # POST /rooms
  # POST /rooms.json
  def create
    # Redis put new  room
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
