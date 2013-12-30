require 'redis'

class REDIS
    @@redis = nil
    @@host = nil
    @@port = nil
    @@RR = nil
    def initialize
        
    end
    def newConnection(host = 'localhost', port = 6379)
        @@host = host
        @@port = port
        @@redis = Redis.new( :host => @@host, :port => @@port );#EM::Protocols::Redis.connect(@@host, @@port)
    end
    def connection(host = 'localhost', port = 6379)
        if (@@RR == nil)
            @RR = REDIS.new.newConnection(host, port);
        end
        return @@redis
    end
    def get(k)
        return @@redis.get(k);
    end
    def set(k, v)
        @@redis.set(k, v);
    end
    def select(db)
        @@redis.select(db)
    end
end