local set1 = KEYS[1]
local set2 = KEYS[2]
local start = KEYS[3]

redis.call("ZREMRANGEBYLEX", set1, "[0", "(" .. start)
redis.call("ZREMRANGEBYLEX", set2, "[0", "(" .. start)

local set1_members = redis.call("ZRANGE", set1, 0, -1, "WITHSCORES")
local set2_members = redis.call("ZRANGE", set2, 0, -1, "WITHSCORES")

local set1_sum = 0
for i = 2, #set1_members, 2 do
	set1_sum = set1_sum + tonumber(set1_members[i])
end

local set2_sum = 0
for i = 2, #set2_members, 2 do
	set2_sum = set2_sum + tonumber(set2_members[i])
end

return {
	set1_sum,
	set2_sum,
}
