JSON = (loadfile("/var/lib/lua/JSON.lua"))()

local os_cluster = "opensearch"
local os_user = "admin"
local os_password = "BkK8[(SdJ*,#&G4g"
local os_index = "envoy"

local function get_os_query(spiffe_id)
	local query = {
		query = {
			bool = {
				must = {
					{ term = { ["spiffe_id.keyword"] = spiffe_id } },
				},
			},
		},
	}

	return query
end

function envoy_on_request(request_handle)
	local uris = request_handle:streamInfo():downstreamSslConnection():uriSanPeerCertificate()

	local spiffe_id = uris[1]

	local query = get_os_query(spiffe_id)
	local data = JSON:encode(query)

	local basic_auth = "Basic " .. request_handle:base64Escape(os_user .. ":" .. os_password)

	local headers, body = request_handle:httpCall(os_cluster, {
		[":method"] = "GET",
		[":path"] = "/" .. os_index .. "/_search",
		[":authority"] = os_cluster,
		["Authorization"] = basic_auth,
		["Content-Type"] = "application/json",
	}, data, 1000)

	if headers[":status"] == "200" then
		data = JSON:decode(body)
		local request_count = data.hits.total.value
		local limit = 2000

		request_handle:logDebug("worked!!! hehe")

		if request_count > limit then
			request_handle:respond({ [":status"] = "429" }, "OVER_LIMIT")
		end
	else
		request_handle:respond({ [":status"] = "500" }, "Internal Server Error")
	end
end
