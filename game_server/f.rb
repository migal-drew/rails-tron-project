require 'eventmachine'
require 'em-websocket'
require 'json'
require 'pp'

require_relative 'sortedArray'
require_relative 'myRedis'
#require_relative 'file_name'



$colors = ["#1E90FF", "#FF0000", "#FFFFFA"]
$rooms = Hash.new
#$redis_host = "192.168.220.143"
$host='localhost'
class TBike
  @@redis = nil #(:host => '192.168.1.3', :port => 6379)
  @user_id = -1
  @data = nil
  @init_pos = nil
  @last_pos = nil
  @w = nil
  @about_user = nil
  @socket = nil
  @connect_type = nil
  @hor_i = nil
  @ver_i = nil
  @speed = nil
  def send(msg)
    print "send messaget #{msg} to user #{@user_id}\n"
    if @connect_type == :CONNECTED
      @socket.send(msg)
      return true
    end
    return false
  end
  @myRoom = nil
  attr_reader :user_id, :connect_type, :hor_i, :ver_i
  attr_accessor :socket, :data, :about_user, :init_pos, :last_pos, :w, :speed
  
  def initialize(socket)
    @@redis = REDIS.new.connection($host);
    @speed = 1
    reset_data()
    @connect_type = :NONE
    @socket = socket
    @socket.onmessage do |mess|
      msg = JSON.parse(mess);
      print "receive '#{mess}' from #{@user_id}"
      case msg["TYPE"]
        when "CONNECT" then connect(msg)
        when "DISCONNECT" then disconnect()
        when "DATA" then ondata(msg)
        when "ADMIN" then onadmin(msg)
      end
    end
    @socket.onclose do
      print "close socket\n"
      if @connect_type == :CONNECTED
        @connect_type = :UNEXPECTED_DISCONNECT
      end
      @socket = nil
    end
    @socket.onerror do |error|
      if (error.kind_of?(EM::WebSocket::WebSocketError))
        print "Web socket error.\n"
        pp error
      end
    end
  end
  
  def copyAll(bike)
    @data = bike.data
    @init_pos = bike.init_pos
    @last_pos = bike.last_pos
    @w = bike.w
    @hor_i = bike.hor_i
    @ver_i = bike.ver_i
    
    
  end
  
  def reset_data
    @data = Array.new
    @ver_i = SortedArray.new {|i| @data[i]["x"]}
    @hor_i = SortedArray.new {|i| @data[i]["y"]}
  end
  
  def reset_to_play
    reset_data();
    @about_user["state"] = :PLAY
  end
  
  def disconnect
    #@myRoom.delUser(self)
    @socket.send("See you later")
    @connect_type = :DISCONNECT
    @socket.close()
  end
  
  def connect(msg)
    @user_id = msg["USER_ID"]
    print "check user #{@user_id}... "
    @@redis.select(0)
    str_about_user = @@redis.get(user_id.to_s)
    if str_about_user != nil
      @about_user = JSON.parse(str_about_user.downcase)
      room_id = @about_user["room_id"].to_i
      print " Successfull.\nTry add user in room #{room_id} "
      if $rooms[room_id] == nil
        print "  (Create room)\n"
        $rooms[room_id] = TRoom.new room_id
      else
        print "  (Room already exist)\n"
      end
      @myRoom = $rooms[room_id]
      if @myRoom.addUser(self) == :SUCCESS
        print "User #{user_id} successfully add\n"
        @connect_type = :CONNECTED
      else
        print "User #{user_id} don't added\n"
        self.disconnect
        connect_type = :ERROR
      end
    else
      print " Deny. User don't found in base\n"
      @socket.send("Sorry. We don't know about you.");
    end
  end
  
  def addToLines()
    x1 = @data[-2]["x"]
    y1 = @data[-2]["y"]
    x2 = @data[-1]["x"]
    y2 = @data[-1]["y"]
    if (x1==x2)
        #Add vertical line
        ver_i.add(@data.length - 2);
    else
        #Add horizontal line
        hor_i.add(@data.length - 2);
    end
  end
  
  def move()
    @last_pos["x"] = @data[-1]["x"];
    @last_pos["y"] = @data[-1]["y"]; 
    case @w
        when 0 then @data[-1]["x"] += @speed
        when 1 then @data[-1]["y"] += @speed
        when 2 then @data[-1]["x"] -= @speed
        when 3 then @data[-1]["y"] -= @speed
    end
  end

  def isCross(arr, val, dim)
    arr.each do |i|
        mm = [val[i][dim], val[i+1][dim]].minmax
        print "bike #{@user_id}, check for #{dim}  #{i} cross #{mm}\n"
        if ((@data[-1][dim]>=mm[0]) and (@data[-1][dim]<=mm[1]))
            return true;
        end
    end
    return false;
  end
  
  def isCrossHead(bb)
    if ((@w + bb.w)%2 == 1)
    #may be cross heads
        yy = 0;
        xx = 0;
        if (@w%2==0)
            #move hor, y=static
            yy = @data[-1]["y"]
            xx = bb.data[-1]["x"]
        else
            yy = bb.data[-1]["y"]
            xx = @data[-1]["x"]
        end
        if ( \
            yy.between?([@data[-1]["y"], @data[-2]["y"]].min, [@data[-1]["y"], @data[-2]["y"]].max) \
        and yy.between?([bb.data[-1]["y"], bb.data[-2]["y"]].min, [bb.data[-1]["y"], bb.data[-2]["y"]].max) \
        and xx.between?([@data[-1]["x"], @data[-2]["x"]].min, [@data[-1]["x"], @data[-2]["x"]].max) \
        and xx.between?([bb.data[-1]["x"], bb.data[-2]["x"]].min, [bb.data[-1]["x"], bb.data[-2]["x"]].max) \
        )
            myD = (@data[-1]["y"] - yy).abs + (@data[-1]["x"] - xx).abs;
            bbD = (bb.data[-1]["y"] - yy).abs + (bb.data[-1]["x"] - xx).abs;
            if (myD<bbD)
                return true;
            end
        end
    end
    return false;
  end
  
  def ondata(msg)
    x = msg["VALUE"]["x"]
    y = msg["VALUE"]["y"]
    dw = msg["VALUE"]["dw"]
    
    addToLines();
    
    @w = (4 + @w + dw) % 4
    
    @data[-1]["x"] = x
    @data[-1]["y"] = y
    @data << msg["VALUE"]
    @myRoom.sendToAll("{\"TYPE\":\"DATA\", \"SOURCE\":\"#{@user_id}\", \"VALUE\":{\"x\":#{x},\"y\":#{y}, \"dw\":#{dw}}}", @user_id)
    
#    self.send("Now data is '#{@data}'")
  end
  
  def onadmin(msg)
    print "\nStart game\n";
    if (@myRoom.room_declare["admin_id"].to_s == @user_id.to_s)
        if (msg["VALUE"] == "PLAY")
                @myRoom.start()
        else 
            if (msg["VALUE"] == "PAUSE")
                @myRoom.stop()
                pp self.data[-1]
                pp self.w
            else
                if (msg["VALUE"] == "RESTART")
                    @myRoom.restart();
                end
            end
        end
    else
        print "Player #{@user_id} is no admin \n"
    end
  end

end

class TRoom
  @@redis = nil
  @bikes = nil
  @id = nil
  @room_declare = nil
  attr_reader :room_declare
  @map_declare = nil
  @play_now = nil
  @timer = nil
  @timeToStart = nil
  def initialize(roomId)
    @timeToStart = 10;
    @bikes = Hash.new
    @@redis = REDIS.new.connection($host);#(:host => '192.168.1.3', :port => 6379)
    @id = roomId
    print "Room #{@id} create "
    @@redis.select(1)
    strInit = @@redis.get(@id.to_s).downcase()
    print "with params: #{strInit}.\n"
    @room_declare = JSON.parse(strInit)
    print "Room declaretion successfull load.\n"
    @@redis.select(2)
    @map_declare = JSON.parse(@@redis.get(@room_declare["map_id"].to_s).downcase)
    @map_declare["period"] = 50
    
    @map_declare["HOR"] = Array.new
    @map_declare["VER"] = Array.new
    @map_declare["walls"].each do |wall|
        @map_declare["HOR"]<< SortedArray.new() {|x| wall[x]["y"]};
        @map_declare["VER"]<< SortedArray.new() {|y| wall[y]["y"]};
        wall.each_index do |i|
            j = i - 1;
            if (wall[j]["x"] == wall[i]["x"])
                #wall is vertical
                @map_declare["VER"][-1].add(j)
            else
                @map_declare["HOR"][-1].add(j)
            end
        end
    end
    print "map declare\n"
    #pp @map_declare
    print "Map declaration successfully load.\n"
  end
  def addUser(bike)
    result = :SUCCESS
    exist_bike = @bikes[bike.user_id]
    if exist_bike == nil
      print "Add new user #{bike.user_id} to room #{@id}.\n"
      @bikes[bike.user_id] = bike
      bike.send("You added to room #{@id}")
    else
      if exist_bike.connect_type == :UNEXPECTED_DISCONNECT or exist_bike.connect_type == :DISCONNECT
        bike.copyAll(exist_bike)
        #bike.data = exist_bike.data
        @bikes[bike.user_id] = bike
        
        print "User #{bike.user_id} again connected after #{exist_bike.connect_type}\n"
      else
        print "User #{bike.user_id} already in room #{@id}.\n"
        bike.send("Sorry. You are already in room")
        result = :UNSUCCESS
      end
    end
    return result
  end
  
  def delUser(bike)
    print "Delete user #{bike.user_id} from room #{@id}. "
    print (@bikes.delete bike)
    print "\n"
  end
  
  def restart
    if (@play_now == 1)
        start()
    end;
  end
  def start
    print "room start \n"
    self.init_map
    print "success map init\n"
    about = ""
    i = 0
    print "generate information about bikes... "
    @bikes.each { |key, value|
      about += "{\"ID\":\"#{key}\", \"POSITION\":#{JSON.generate(value.init_pos)}, \"COLOR\":\"#{$colors[i]}\"},"
      i += 1
    }
    @play_now = @bikes.length
    print "ok\nsend information to all... "
    sendToAll("{\"TYPE\":\"INIT\", \"PERIOD\":#{@map_declare["period"]}, \"VALUE\":[#{about.chop()}], \"MAP\":#{JSON.generate(@map_declare["walls"])}}")
    print "ok\n"
    interval = 1.0 * @map_declare["period"]
    interval /= 1000
    @timeToStart = 1
    @beforeStartTimer = EventMachine::PeriodicTimer.new(1) do
        if (@timeToStart == 0)
            sendToAll("{\"TYPE\":\"START\", \"VALUE\":\"NOW\"}")
            @timer = EventMachine::PeriodicTimer.new(interval) do
              self.iteration()
            end
            @beforeStartTimer.cancel
        else
            sendToAll("{\"TYPE\":\"START\", \"VALUE\":\"#{@timeToStart}\"}")
            @timeToStart = @timeToStart - 1
        end
        
    end
  end
  def stop
    @timer.cancel
  end

  def init_map
    @bikes.each do |key, value|
        value.reset_to_play()
        pp @map_declare["init_positions"]
        pp value.about_user["bike_num"]
        value.init_pos = @map_declare["init_positions"][value.about_user["bike_num"]]
        y = value.init_pos["y"]
        x = value.init_pos["x"]
        lp = Hash.new
        lp["x"] = x
        lp["y"] = y
        lp["dw"] = 0
        value.data << value.init_pos
        value.data << lp

        value.last_pos = Hash.new
        value.last_pos["x"] = x;
        value.last_pos["y"] = y;
        value.w = value.init_pos["w"]
    end
  end
  
  def iteration
    #Move all bikes
    @bikes.each do |key, value|
      if (value.about_user["state"] == :GAME_OVER)
        next
      end
      value.move()
    end
    
    @bikes.each do |key, value|
        if (value.about_user["state"] == :GAME_OVER)
            next
        end
        xBefore = value.last_pos["x"]
        yBefore = value.last_pos["y"]      
        xNow = value.data[-1]["x"]
        yNow = value.data[-1]["y"]
        
        xStart = [xBefore, xNow].min
        yStart = [yBefore, yNow].min
        xEnd   = [xBefore, xNow].max
        yEnd   = [yBefore, yNow].max
        
        isGameOver = false;
        
        #check for cross with wall
        if (value.w % 2 == 0)
            @map_declare["VER"].each_index do |i|
                wall = @map_declare["VER"][i];
                arr = wall.getBetween(xStart, xEnd);
                isGameOver = value.isCross(arr, @map_declare["walls"][i], "y");
                if (isGameOver)
                    break;
                end
            end
        else
            @map_declare["HOR"].each_index do |i|
                wall = @map_declare["HOR"][i];
                arr = wall.getBetween(yStart, yEnd);
                isGameOver = value.isCross(arr, @map_declare["walls"][i], "x");
                if (isGameOver)
                    break;
                end
            end
        end
        if not isGameOver
            @bikes.each do |checkK, checkV|
                if (value.w % 2 == 0)
                #bike move Horizontal. Check for Vertical
                    #check for all path
                    arr = checkV.ver_i.getBetween(xStart, xEnd)
                    arr.delete_if {|i| checkV.data[i+1]["y"]==yBefore and checkV.data[i+1]["x"]==xBefore}
                    isGameOver = value.isCross(arr, checkV.data, "y");
                    if (isGameOver)
                        break;
                    end
                else
                #bike move Vertical. Check for Horizontal
                    arr = checkV.hor_i.getBetween(yStart, yEnd)
                    arr.delete_if {|i| checkV.data[i+1]["y"]==yBefore and checkV.data[i+1]["x"]==xBefore}
                    isGameOver = value.isCross(arr, checkV.data, "x");
                    if (isGameOver)
                        break;
                    end
                end
                #check cross heads
                isGameOver = value.isCrossHead(checkV);
                if (isGameOver)
                    break;
                end
            end
        end  
      if (isGameOver and value.about_user["state"] != :GAME_OVER)
        value.about_user["state"] = :GAME_OVER
        sendToAll("{\"TYPE\":\"GAME\",\"VALUE\":\"GAME_OVER\", \"SOURCE\":\"#{value.user_id}\"}")
        @play_now -= 1;
      end
    end
    if @play_now == 1
      self.stop
      winner = nil
      @bikes.each do |key, value|
        if (value.about_user["state"] != :GAME_OVER)
            winner = value
            break;
        end
      end
      sendToAll("{\"TYPE\":\"GAME\",\"VALUE\":\"WIN\", \"SOURCE\":\"#{winner.user_id}\"}")
    end
  end
  
  def sendToAll (msg, user=nil)
    @bikes.each { |key, value|
      if (key != user)
        value.send(msg)
      end
      }
  end
end

EventMachine.run do
  print "Start server on port 3000\n"
  EventMachine::WebSocket.start(:host => '0.0.0.0', :port => 3001) do |socket|
    socket.onopen do
      TBike.new socket
      print "got connection\n"
    end
    socket.onclose do
      print "del connection\n"
    end
  end
end
