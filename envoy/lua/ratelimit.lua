JSON = (loadfile("/var/lib/lua/JSON.lua"))()

local webdis_cluster = "webdis"

local function get_path(spiffe_id)
	local path = "/MGET/" .. spiffe_id:gsub("/", "%%2F") .. "/global_scope"

	return path
end

function envoy_on_request(request_handle)
	local uris = request_handle:streamInfo():downstreamSslConnection():uriSanPeerCertificate()

	local spiffe_id = uris[1]

	local path = get_path(spiffe_id)

	local headers, body = request_handle:httpCall(webdis_cluster, {
		[":method"] = "GET",
		[":path"] = path,
		[":authority"] = webdis_cluster,
	}, "", 1000)

	if headers[":status"] == "200" then
		local data = JSON:decode(body)

		local alerts = tonumber(data["MGET"][1]) or 0
		local global_scope = tonumber(data["MGET"][2]) or 0

		if global_scope > 0 then
			local response = {
				message = "The server might be overloaded. Please try again later",
			}

			request_handle:respond({ [":status"] = "429" }, JSON:encode(response))
		end

		if alerts > 0 then
			local response = {
				message = "You have exceeded your request limit. Please wait before making further requests.",
			}

			request_handle:respond({ [":status"] = "429" }, JSON:encode(response))
		end
	end
end
