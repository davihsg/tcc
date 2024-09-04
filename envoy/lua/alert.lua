JSON = (loadfile("/var/lib/lua/JSON.lua"))()

WEBDIS_CLUSTER = "webdis"
OS_CLUSTER = "opensearch"
OS_TOKEN = "YWRtaW46QmtLOFsoU2RKKiwjJkc0Zw=="
ALERT_INDEX = "envoy_alerts"
GLOBAL_KEY = "global"
BITS = 33

local function iso8601_to_epoch(iso_timestamp)
	local year, month, day, hour, min, sec = iso_timestamp:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+).%d+Z")

	local time_table = {
		year = tonumber(year),
		month = tonumber(month),
		day = tonumber(day),
		hour = tonumber(hour),
		min = tonumber(min),
		sec = tonumber(sec),
		isdst = false,
	}

	local epoch_time = os.time(time_table) - os.difftime(os.time(), os.time(os.date("!*t")))

	return math.floor(epoch_time)
end

local function url_encode(str)
	if str then
		str = string.gsub(str, "\n", "\r\n")
		str = string.gsub(str, "([^%w%-%.%_%~])", function(c)
			return string.format("%%%02X", string.byte(c))
		end)
	end
	return str
end

local function tobin(n)
	n = math.floor(n)

	local bin = ""

	for _ = 1, BITS do
		local r = n % 2
		n = math.floor(n / 2)
		bin = r .. bin
	end

	return bin
end

local function get_penalty(severity)
	if severity == 5 then
		return 1
	elseif severity == 4 then
		return 2
	elseif severity == 3 then
		return 3
	elseif severity == 2 then
		return 4
	elseif severity == 1 then
		return 5
	end
end

function envoy_on_request(request_handle)
	local body = request_handle:body()
	local data = body:getBytes(0, body:length())

	local notification = JSON:decode(data)

	local alerts = notification.alerts

	for _, alert in pairs(alerts) do
		if alert == nil then
			goto continue
		end

		-- processing alert

		local penalty = get_penalty(alert.trigger_severity)

		local key = alert.global_scope and GLOBAL_KEY or alert.key
		key = url_encode(key)

		local epoch = iso8601_to_epoch(alert.period_end)
		local bin = tobin(epoch)

		request_handle:httpCall(WEBDIS_CLUSTER, {
			[":method"] = "GET",
			[":path"] = "/ZINCRBY/" .. key .. "/" .. penalty .. "/" .. bin,
			[":authority"] = WEBDIS_CLUSTER,
		}, "", 1000)

		request_handle:httpCall(OS_CLUSTER, {
			[":method"] = "POST",
			[":path"] = "/" .. ALERT_INDEX .. "/_doc",
			[":authority"] = OS_CLUSTER,
			["Content-Type"] = "application/json",
			["Authorization"] = "Basic " .. OS_TOKEN,
		}, JSON:encode(alert), 5000)

		::continue::
	end
end
