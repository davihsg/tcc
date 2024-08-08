JSON = (loadfile("/var/lib/lua/JSON.lua"))()

local os_cluster = "opensearch"
local os_user = "admin"
local os_password = "BkK8[(SdJ*,#&G4g"

local monitorId = "8yW7L5EBp1H7vfUalij1" -- add the monitor id here

local function get_path()
	local path = "/_plugins/_alerting/monitors/alerts"

	path = path .. "?monitorId=" .. monitorId
	path = path .. "&alertState=ACTIVE"

	return path
end

function envoy_on_request(request_handle)
	local uris = request_handle:streamInfo():downstreamSslConnection():uriSanPeerCertificate()

	local spiffe_id = uris[1]

	local basic_auth = "Basic " .. request_handle:base64Escape(os_user .. ":" .. os_password)
	local path = get_path()

	local headers, body = request_handle:httpCall(os_cluster, {
		[":method"] = "GET",
		[":path"] = path,
		[":authority"] = os_cluster,
		["Authorization"] = basic_auth,
	}, "", 1000)

	if headers[":status"] == "200" then
		local data = JSON:decode(body)

		for _, alert in ipairs(data.alerts) do
			for _, spiffe_id_alert in ipairs(alert.agg_alert_content.bucket_keys) do
				if spiffe_id_alert == spiffe_id then
					request_handle:respond({ [":status"] = "429" }, "OVER_LIMIT")
				end
			end
		end
	else
		request_handle:respond({ [":status"] = "500" }, "Internal Server Error") -- remove it to ignore errors
	end
end
