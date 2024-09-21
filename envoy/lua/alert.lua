JSON = (loadfile("/var/lib/lua/JSON.lua"))()

WEBDIS_CLUSTER = "webdis"
OS_CLUSTER = "opensearch"
OS_TOKEN = "YWRtaW46QmtLOFsoU2RKKiwjJkc0Zw=="
ALERT_INDEX = "envoy_alerts"
GLOBAL_KEY = "global"

local function url_encode(str)
	if str then
		str = string.gsub(str, "\n", "\r\n")
		str = string.gsub(str, "([^%w%-%.%_%~])", function(c)
			return string.format("%%%02X", string.byte(c))
		end)
	end
	return str
end

local function get_penalty(severity)
	if severity == 5 then
		return 1 -- penalty for P5 alerts (lowest)
	elseif severity == 4 then
		return 2 -- penalty for P4 alerts
	elseif severity == 3 then
		return 3 -- penalty for P3 alerts
	elseif severity == 2 then
		return 4 -- penalty for P2 alerts
	elseif severity == 1 then
		return 5 -- penalty for P1 alerts (highest)
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

		local start = alert.period_end

		request_handle:httpCall(WEBDIS_CLUSTER, {
			[":method"] = "GET",
			[":path"] = "/ZINCRBY/" .. key .. "/" .. penalty .. "/" .. start,
			[":authority"] = WEBDIS_CLUSTER,
		}, "", 1000)

		-- sending alert to opensearch

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
