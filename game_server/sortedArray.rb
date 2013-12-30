class SortedArray
    @array = nil
    @cmp_expr = nil
    def initialize (init_arr = [], &compare_expr)
        @array = Array.new (init_arr)
        if (compare_expr)
            @cmp_expr = compare_expr
        else
            @cmp_expr = Proc.new {|x| x}
        end
    end
    
    def getAbove(v)
        if (@array.length == 0)
            return nil;
        end
        left = 0;
        right = @array.length - 1;
        if (v > @cmp_expr.call(@array[right]))
            return nil;
        end
        if (v <= @cmp_expr.call(@array[left]))
            return left;
        end
        
        while (left + 1 != right) do
            cur = ((left+right)/2).round;
            if (v > @cmp_expr.call(@array[cur]))
                left = cur;
            else 
                if (v < @cmp_expr.call(@array[cur]))
                    right = cur;
                else
                    left = cur - 1;
                    right = cur;
                end
            end
        end
        return right;
    end
    
    def getBelow(v)
        if (@array.length == 0)
            return nil;
        end
        left = 0;
        right = @array.length - 1;
        if (v >= @cmp_expr.call(@array[right]))
            return right;
        end
        if (v < @cmp_expr.call(@array[left]))
            return nil;
        end
        
        while (left != right-1) do
            cur = ((left+right)/2).round;
            if (v > @cmp_expr.call(@array[cur]))
                left = cur;
            else 
                if (v < @cmp_expr.call(@array[cur]))
                    right = cur;
                else
                    left = cur;
                    right = cur + 1;
                end
            end
        end
        return left;
    end
    
    def [](i)
        return @array[i]
    end
    
    def out()
        print @array, "\n"
    end
    def outV()
        print "["
        @array.each {|i| print "#{@cmp_expr.call(i)}, "}
        print "]\n"
    end
    
    def add(value)
        pos = getAbove(@cmp_expr.call(value));
        if (pos == nil)
            @array<<value;
        else
            @array.insert(pos, value);
        end
    end
    
    def getBetween(v1, v2)
        p1 = getAbove(v1);
        p2 = getBelow(v2);
        if (p1==nil or p2==nil)
            return Array.new([]);
        end
        return @array[p1..p2];
    end
end;