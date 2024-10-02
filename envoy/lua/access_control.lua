JSON = (loadfile("/var/lib/lua/JSON.lua"))()

WEBDIS_CLUSTER = "webdis"
GLOBAL_KEY = "global"
WINDOW_SIZE = 300 -- in seconds
PENALTY_LIMIT = 3

local function url_encode(str)
	if str then
		str = string.gsub(str, "\n", "\r\n")
		str = string.gsub(str, "([^%w%-%.%_%~])", function(c)
			return string.format("%%%02X", string.byte(c))
		end)
	end
	return str
end

local function generate_redis_script()
	local script = [[
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
]]

	return script
end

function envoy_on_request(request_handle)
	local uris = request_handle:streamInfo():downstreamSslConnection():uriSanPeerCertificate()

	local key = uris[1] -- spiffe_id

	local start = os.date("!%Y-%m-%dT%H:%M:%S", os.time() - WINDOW_SIZE) .. "Z"

	request_handle:logDebug(start)

	local script = generate_redis_script()

	local path = "/EVAL/"
		.. url_encode(script)
		.. "/3/"
		.. url_encode(key)
		.. "/"
		.. url_encode(GLOBAL_KEY)
		.. "/"
		.. start

	local headers, body = request_handle:httpCall(WEBDIS_CLUSTER, {
		[":method"] = "GET",
		[":path"] = path,
		[":authority"] = WEBDIS_CLUSTER,
	}, "", 1000)

	local response = {
		message = "You have exceeded your request limit. Please wait before making further requests.",
	}

	if headers[":status"] == "200" then
		local data = JSON:decode(body)

		local alerts = tonumber(data["EVAL"][1]) or 0
		local global_scope = tonumber(data["EVAL"][2]) or 0

		if global_scope > PENALTY_LIMIT then
			request_handle:respond({ [":status"] = "429" }, JSON:encode(response))
		end

		if alerts > PENALTY_LIMIT then
			request_handle:respond({ [":status"] = "429" }, JSON:encode(response))
		end
	else
		request_handle:respond({ [":status"] = "429" }, JSON:encode(response))
	end
end
