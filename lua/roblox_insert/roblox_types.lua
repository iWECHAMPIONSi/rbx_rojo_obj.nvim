local roblox_types = {}
local data = require("roblox_insert.data")
local brick_colors = data.colors
local enums = data.raw.Enums
local vim = vim

local font_families = {
	["Accanthis ADF Std"] = "AccanthisADFStd",
	["Amatic SC"] = "AmaticSC",
	["Arimo"] = "Arimo",
	["Balthazar"] = "Balthazar",
	["Bangers"] = "Bangers",
	["Builder Extended"] = "BuilderExtended",
	["Builder Mono"] = "BuilderMono",
	["Builder Sans"] = "BuilderSans",
	["Comic Neue Angular"] = "ComicNeueAngular",
	["Creepster"] = "Creepster",
	["Denk One"] = "DenkOne",
	["Fondamento"] = "Fondamento",
	["Fredoka One"] = "FredokaOne",
	["Grenze Gotisch"] = "GrenzeGotisch",
	["Guru"] = "Guru",
	["Highway Gothic"] = "HighwayGothic",
	["Inconsolata"] = "Inconsolata",
	["Indie Flower"] = "IndieFlower",
	["Josefin Sans"] = "JosefinSans",
	["Jura"] = "Jura",
	["Kalam"] = "Kalam",
	["Luckiest Guy"] = "LuckiestGuy",
	["Merriweather"] = "Merriweather",
	["Michroma"] = "Michroma",
	["Montserrat"] = "Montserrat",
	["Nunito"] = "Nunito",
	["Oswald"] = "Oswald",
	["Patrick Hand"] = "PatrickHand",
	["Permanent Marker"] = "PermanentMarker",
	["Press Start 2P"] = "PressStart2P",
	["Roboto"] = "Roboto",
	["Roboto Condensed"] = "RobotoCondensed",
	["Roboto Mono"] = "RobotoMono",
	["Roman Antique"] = "RomanAntique",
	["Sarpanch"] = "Sarpanch",
	["Source Sans Pro"] = "SourceSansPro",
	["Special Elite"] = "SpecialElite",
	["Titillium Web"] = "TitilliumWeb",
	["Ubuntu"] = "Ubuntu",
	["Zekton"] = "Zekton",
}

-- Legacy Enum.Font names that differ from the family filename.
local font_aliases = {
	Antique = "RomanAntique",
	Arcade = "PressStart2P",
	Arial = "Arimo",
	ArialBold = "Arimo",
	ArimoBold = "Arimo",
	Bodoni = "AccanthisADFStd",
	BuilderSansMedium = "BuilderSans",
	BuilderSansBold = "BuilderSans",
	BuilderSansExtraBold = "BuilderSans",
	Cartoon = "ComicNeueAngular",
	Code = "Inconsolata",
	Fantasy = "Balthazar",
	Garamond = "Guru",
	Highway = "HighwayGothic",
	Legacy = "LegacyArial",
	SciFi = "Zekton",
	SourceSans = "SourceSansPro",
	SourceSansBold = "SourceSansPro",
	SourceSansItalic = "SourceSansPro",
	SourceSansLight = "SourceSansPro",
	SourceSansSemibold = "SourceSansPro",
}

local font_lookup = {}

for display_name, filename in pairs(font_families) do
	font_lookup[display_name] = filename
	font_lookup[filename] = filename
end

for alias, filename in pairs(font_aliases) do
	font_lookup[alias] = filename
end

---@param name string
---@return boolean, string?, string?
local function verify_font(name)
	local filename = font_lookup[name]

	if not filename then
		return false, nil, "Font not Found"
	end

	return true, filename
end

---@param t string
---@return boolean
local function handle_nil(t)
	if t == "nil" then
		return true
	end
	return false
end

---@param v number|string
---@param min number
---@param max number
---@param default number?
---@return number
local function clamp(v, min, max, default)
	v = tonumber(v) or 0
	return math.max(min, math.min(max, tonumber(v) or default or min))
end

---@param enum string
---@param field string
---@return boolean, number?, string?
local function verify_enum(enum, field)
	local value = enums[enum][field]
	return value ~= nil, value, value == nil and (enum .. " does not have a field named " .. tostring(field)) or nil
end

---@param t {Hex: string?, R: string?, G: string?, B: string?}
---@return boolean, number[]?, {R: string, G: string, B: string}?, string?
local function verify_color_3(t)
	local return_val = {}
	if t.Hex then
		if type(t.Hex) == "string" then
			if string.match(t.Hex, "^%x%x%x%x%x%x$") then
				return_val = {
					math.min(tonumber(string.sub(t.Hex, 1, 2), 16), 255) / 255.0,
					math.min(tonumber(string.sub(t.Hex, 3, 4), 16), 255) / 255.0,
					math.min(tonumber(string.sub(t.Hex, 5, 6), 16), 255) / 255.0,
				}
				return true,
					return_val,
					{
						Hex = nil,
						R = tostring(return_val[1] * 255.0),
						G = tostring(return_val[2] * 255.0),
						B = tostring(return_val[3] * 255.0),
					}
			end
		end
	end
	local indexes = 0
	for k, i in pairs(t) do
		indexes = indexes + 1
		if tonumber(i) == nil and k ~= "Hex" then
			return false, nil, nil, "Color Not Specified or is Invalid"
		end
		return_val[k] = tonumber(i)
	end
	if indexes == 3 and return_val.Hex == nil or indexes == 4 then
		return_val = {
			clamp(return_val.R, 0, 255) / 255.0,
			clamp(return_val.G, 0, 255) / 255.0,
			clamp(return_val.B, 0, 255) / 255.0,
		}
		return true,
			return_val,
			{
				Hex = nil,
				R = tostring(return_val[1] * 255.0),
				G = tostring(return_val[2] * 255.0),
				B = tostring(return_val[3] * 255.0),
			}
	end
	return false, nil, nil, "Color Not Specified or is Invalid"
end

---@param t { X: string?, Y: string?, Z: string? }
---@return boolean, number[]?, {X: string?, Y: string?, Z: string?}, string?
local function verify_vector_3(t)
	local return_val = {}
	local indexes = 0
	for k, i in pairs(t) do
		indexes = indexes + 1
		if tonumber(i) == nil then
			return false, nil, t, "All fields must contain a number"
		end
		return_val[k] = tonumber(i)
	end
	if indexes == 3 then
		return_val = {
			return_val.X,
			return_val.Y,
			return_val.Z,
		}
		return true, return_val, t
	end
	return false, nil, t, "All fields must contain a number"
end

---@param t { X: string?, Y: string?}
---@return boolean, number[]?, {X: string?, Y: string?}, string?
local function verify_vector_2(t)
	local return_val = {}
	local indexes = 0
	for k, i in pairs(t) do
		indexes = indexes + 1
		if tonumber(i) == nil then
			return false, nil, t, "All fields must contain a number"
		end
		return_val[k] = tonumber(i)
	end
	if indexes == 2 then
		return_val = {
			return_val.X,
			return_val.Y,
		}
		return true, return_val, t
	end
	return false, nil, t, "All fields must contain a number"
end

roblox_types.Axes = {
	lua_type = "table",
	fields = {
		"X",
		"Y",
		"Z",
	},
	---@param t {X: string?, Y: string?, Z: string?}
	---@return boolean, string[], {X: string?, Y: string?, Z: string?}
	verification = function(t)
		local return_val = {}
		if t.X == "true" then
			table.insert(return_val, "X")
		end
		if t.Y == "true" then
			table.insert(return_val, "Y")
		end
		if t.Z == "true" then
			table.insert(return_val, "Z")
		end
		return true, return_val, t
	end,
	---@param t any?
	---@return boolean, boolean, {X: string?, Y: string?, Z: string?}?
	reverse = function(t)
		if type(t) ~= "table" then
			return false, false, nil
		end
		local return_val = {}
		for i = 1, 3 do
			local face = t[i]
			if face and (face == "X" or face == "Y" or face == "Z") then
				return_val[face] = "true"
			end
		end
		return true, true, return_val
	end,
}

roblox_types.BinaryString = {
	lua_type = "string",
	fields = {
		"",
	},
	---@param t string
	---@return boolean, string?
	verification = function(t)
		if handle_nil(t) then
			return true, nil
		end
		if not string.match(t, "^[%w+/]*=?=?$") then
			return false, nil
		end
		return true, t
	end,
	---@param t any?
	---@return boolean, boolean, string?
	reverse = function(t)
		if type(t) ~= "string" then
			return false, false, nil
		end

		if not string.match(t, "^[%w+/]*=?=?$") then
			return false, true, nil
		end
		return true, true, t
	end,
}

roblox_types.Bool = {
	lua_type = "bool",
	fields = {
		"",
	},
	---@param t string
	---@return boolean, boolean?
	verification = function(t)
		if handle_nil(t) then
			return true, nil
		end
		if t == "true" or t == "false" then
			if t == "true" then
				return true, true
			else
				return true, false
			end
		end
		return false, nil
	end,
	---@param t any?
	---@return boolean, boolean, string?
	reverse = function(t)
		if type(t) ~= "boolean" then
			return false, false, nil
		end
		return true, true, tostring(t)
	end,
}

roblox_types.BrickColor = {
	lua_type = "string",
	fields = {
		"Color",
	},
	---@param t string
	---@return boolean, integer?
	verification = function(t)
		if handle_nil(t) then
			return true, nil
		end
		local number = tonumber(t)

		if number then
			return brick_colors[number] ~= nil, number
		end

		return brick_colors[t] ~= nil, brick_colors[t]
	end,
	---@param t any?
	---@return boolean, boolean, string?
	reverse = function(t)
		if type(t) ~= "number" then
			return false, false, nil
		end
		return true, true, tostring(t)
	end,
}

roblox_types.CFrame = {
	lua_type = "table",
	fields = {
		"X",
		"Y",
		"Z",
		"R00",
		"R01",
		"R02",
		"R10",
		"R11",
		"R12",
		"R20",
		"R21",
		"R22",
	},
	---@param t {X: string?, Y: string?, Z: string?, R00: string?, R01: string?, R02: string?, R10: string?, R11: string?, R12: string?, R20: string?, R21: string?, R22: string?}
	---@return boolean, {position: number[], orientation: number[][]}?, {X: string, Y: string, Z: string, R00: string, R01: string, R02: string, R10: string, R11: string, R12: string, R20: string, R21: string, R22: string}?, string?
	verification = function(t)
		local return_val = {}
		local indexes = 0
		for k, i in pairs(t) do
			indexes = indexes + 1
			if tonumber(i) == nil then
				return false, nil, nil, "'" .. i .. "' is not a valid number"
			end
			return_val[k] = tonumber(i)
		end
		if indexes >= 3 then
			if return_val.X ~= nil and return_val.Y ~= nil and return_val.Z ~= nil then
				local copy = vim.deepcopy(return_val)
				return_val = {
					position = { return_val.X, return_val.Y, return_val.Z },
					orientation = {
						{ return_val.R00 or 1.0, return_val.R01 or 0.0, return_val.R02 or 0.0 },
						{ return_val.R10 or 0.0, return_val.R11 or 1.0, return_val.R12 or 0.0 },
						{ return_val.R20 or 0.0, return_val.R21 or 0.0, return_val.R22 or 1.0 },
					},
				}
				return true,
					return_val,
					{
						X = tostring(copy.X),
						Y = tostring(copy.Y),
						Z = tostring(copy.Z),
						R00 = tostring(copy.R00 or "1.0"),
						R01 = tostring(copy.R01 or "0.0"),
						R02 = tostring(copy.R02 or "0.0"),
						R10 = tostring(copy.R10 or "0.0"),
						R11 = tostring(copy.R11 or "1.0"),
						R12 = tostring(copy.R12 or "0.0"),
						R20 = tostring(copy.R20 or "0.0"),
						R21 = tostring(copy.R21 or "0.0"),
						R22 = tostring(copy.R22 or "1.0"),
					}
			end
			return false, nil, nil, "X, Y, and Z must contain a number"
		end
		return false, nil, nil, "X, Y, and Z must contain a number"
	end,
	---@param t any?
	---@return boolean, boolean, {X: string, Y: string, Z: string, R00: string, R01: string, R02: string, R10: string, R11: string, R12: string, R20: string, R21: string, R22: string}?
	reverse = function(t)
		if type(t) ~= "table" then
			return false, false, nil
		end

		local return_val = {}
		if not t.position then
			return false, true, return_val
		end
		return_val.X, return_val.Y, return_val.Z =
			tostring(t.position[1] or ""), tostring(t.position[2] or ""), tostring(t.position[3] or "")
		if t.orientation then
			if t.orientation[1] then
				return_val.R00, return_val.R01, return_val.R02 =
					tostring(t.orientation[1][1] or ""),
					tostring(t.orientation[1][2] or ""),
					tostring(t.orientation[1][3] or "")
				if t.orientation[2] then
					return_val.R10, return_val.R11, return_val.R12 =
						tostring(t.orientation[2][1] or ""),
						tostring(t.orientation[2][2] or ""),
						tostring(t.orientation[2][3] or "")
					if t.orientation[3] then
						return_val.R20, return_val.R21, return_val.R22 =
							tostring(t.orientation[3][1] or ""),
							tostring(t.orientation[3][2] or ""),
							tostring(t.orientation[3][3] or "")
					end
				end
			end
		end
		return true, true, return_val
	end,
}

---@param t any?
---@return boolean, boolean, {R: string, G: string, B: string}?
local function revert_color_3(t)
	if type(t) ~= "table" then
		return false, false, nil
	end
	local return_val = {}

	return_val.R = tostring(t[1] and (t[1] * 255.0) or "")
	return_val.G = tostring(t[2] and (t[2] * 255.0) or "")
	return_val.B = tostring(t[3] and (t[3] * 255.0) or "")

	return true, true, return_val
end

roblox_types.Color3 = {
	lua_type = "table",
	fields = {
		"Hex",
		"R",
		"G",
		"B",
	},
	---@param t {Hex: string?, R: string?, G: string?, B: string?}
	---@return boolean, number[]?, {R: string, G: string, B: string}?, string?
	verification = function(t)
		return verify_color_3(t)
	end,
	---@param t any?
	---@return boolean, boolean, {R: string, G: string, B: string}?
	reverse = function(t)
		return revert_color_3(t)
	end,
}

roblox_types.ColorSequence = {
	lua_type = "nested table",
	fields = {
		"time",
		"Hex",
		"R",
		"G",
		"B",
	},
	---@param t {time: string?, Hex: string?, R: string?, G: string?, B: string? }[]
	---@return boolean, {keypoints: {time: number, color: number[]}}?, {time: string, R: string, G: string, B: string }[]?, string?
	verification = function(t)
		local return_val = {}
		local correct = {}
		for i, keypoint in ipairs(t) do
			local valid, k, corrected, msg =
				verify_color_3({ R = keypoint.R, G = keypoint.G, B = keypoint.B, Hex = keypoint.Hex })
			if valid then
				if not corrected then
					error("unreachable state reached")
				end
				local time = tonumber(keypoint.time)
				if (not time) or time > 1 or time < 0 then
					return false, nil, nil, "Invalid at keypoint " .. i .. ", time must be a number in range [0, 1]"
				end
				table.insert(correct, { time = time, R = corrected.R, G = corrected.G, B = corrected.B })
				table.insert(return_val, {
					time = time,
					color = k,
				})
			else
				return false, nil, nil, "Invalid at keypoint " .. i .. ", " .. msg
			end
		end
		table.sort(return_val, function(a, b)
			return a.time < b.time
		end)
		table.sort(correct, function(a, b)
			return tonumber(a.time) < tonumber(b.time)
		end)
		local msg
		if #return_val < 2 then
			msg = "Must have minimum of 2 keypoints"
		elseif #return_val > 20 then
			msg = "Cannot have more than 20 keypoints"
		elseif return_val[1].time ~= 0.0 then
			msg = "At least one keypoint must have a time value of 0"
		elseif return_val[#return_val].time ~= 1.0 then
			msg = "At least one keypoint must have a time value of 1.0"
		end
		return #return_val >= 2
			and #return_val <= 20
			and return_val[1].time == 0.0
			and return_val[#return_val].time == 1.0,
			{ keypoints = return_val },
			correct,
			msg
	end,

	---@param t any?
	---@return boolean, boolean, {time: string, R: string, G: string, B: string }[]?
	reverse = function(t)
		if type(t) ~= "table" then
			return false, false, nil
		end
		local return_val = {}
		if type(t.keypoints) ~= "table" then
			return false, false, nil
		end
		for _, keypoint in ipairs(t.keypoints) do
			local key = {}
			key.time = keypoint.time
			local valid, _, color = revert_color_3(keypoint.color)
			if valid and color then
				key.R, key.G, key.B = color.R, color.G, color.B
				table.insert(return_val, key)
			end
		end
		return true, true, return_val
	end,
}

roblox_types.Content = {
	lua_type = "number",
	fields = {
		"rbxassetid://",
	},
	---@param t string
	---@return boolean, string?
	verification = function(t)
		local i = tonumber(t)
		if i == nil then
			return false, nil
		end
		return math.floor(i) == i, "rbxassetid://" .. (i or "")
	end,
	---@param t any?
	---@return boolean, boolean, string?
	reverse = function(t)
		if type(t) ~= "string" then
			return false, false, nil
		end

		if string.len(t) <= string.len("rbxassetid://") then
			return false, true, ""
		end

		local num = tonumber(string.sub(t, string.len("rbxassetid:// ")))
		return num ~= nil, true, tostring(num or "")
	end,
}

roblox_types.ContentId = {
	lua_type = "number",
	fields = {
		"rbxassetid://",
	},
	---@param t string
	---@return boolean, string?
	verification = function(t)
		local i = tonumber(t)
		if i == nil then
			return false, nil
		end
		return math.floor(i) == i, "rbxassetid://" .. (i or "")
	end,
	---@param t any?
	---@return boolean, boolean, string?
	reverse = function(t)
		if type(t) ~= "string" then
			return false, false, nil
		end

		if string.len(t) <= string.len("rbxassetid://") then
			return false, true, ""
		end

		local num = tonumber(string.sub(t, string.len("rbxassetid:// ")))
		return num ~= nil, true, tostring(num or "")
	end,
}

roblox_types.Enum = {
	lua_type = "enum",
	fields = {
		"",
	},
	---@param enum string
	---@param field string
	---@return boolean, number?, string?
	verification = function(enum, field)
		if handle_nil(field) then
			return true, nil
		end
		return verify_enum(enum, field)
	end,
	reverse = function(enum, t)
		if type(t) ~= "number" then
			return false, false, nil
		end
		for name, value in pairs(enums[enum]) do
			if value == t then
				return true, true, name
			end
		end
		return false, true, ""
	end,
}

roblox_types.Faces = {
	lua_type = "table",
	fields = {
		"Right",
		"Top",
		"Back",
		"Left",
		"Bottom",
		"Front",
	},
	---@param t {Right: string?, Top: string?, Back: string?, Left: string?, Bottom: string?, Front: string? }
	---@return boolean, string[]?, {Right: string?, Top: string?, Back: string?, Left: string?, Bottom: string?, Front: string? }?
	verification = function(t)
		local return_val = {}

		for face, value in pairs(t) do
			if value == "true" then
				table.insert(return_val, face)
			end
		end
		return true, return_val, t
	end,
	---@param t any?
	---@return boolean, boolean,{Right: string?, Top: string?, Back: string?, Left: string?, Bottom: string?, Front: string? }?
	reverse = function(t)
		if type(t) ~= "table" then
			return false, false, nil
		end

		local return_val = {}
		for i = 1, 6 do
			local name = t[i]
			if not name then
				break
			end
			if
				name == "Right"
				or name == "Top"
				or name == "Back"
				or name == "Left"
				or name == "Bottom"
				or name == "Front"
			then
				return_val[name] = "true"
			end
		end
		return true, true, return_val
	end,
}

roblox_types.Float32 = {
	lua_type = "number",
	fields = {
		"",
	},
	---@param t string
	---@return boolean, number?
	verification = function(t)
		if handle_nil(t) then
			return true, nil
		end
		return tonumber(t) ~= nil, tonumber(t)
	end,
	---@param t any?
	---@return boolean, boolean, string?
	reverse = function(t)
		if type(t) ~= "number" then
			return false, false, nil
		end
		return true, true, tostring(t)
	end,
}

roblox_types.Float64 = {
	lua_type = "number",
	fields = {
		"",
	},
	---@param t string
	---@return boolean, number?
	verification = function(t)
		if handle_nil(t) then
			return true, nil
		end
		return tonumber(t) ~= nil, tonumber(t)
	end,
	---@param t any?
	---@return boolean, boolean, string?
	reverse = function(t)
		if type(t) ~= "number" then
			return false, false, nil
		end
		return true, true, tostring(t)
	end,
}

roblox_types.Font = {
	lua_type = "table",
	fields = {
		"family",
		"weight",
		"style",
	},
	---@param t {family: string?, weight: string?, style: string?}
	---@return boolean, {family: string, weight: string, style: string}?, {family: string, weight: string, style: string}?, string?
	verification = function(t)
		local tmp = vim.deepcopy(t)
		local family = t.family
		if family then
			local non_null_family = family
			local return_val = {}

			local valid, msg
			valid, family, msg = verify_font(non_null_family)
			tmp.family = t.family
			if valid then
				return_val.family = "rbxasset://fonts/families/" .. non_null_family .. ".json"
			else
				return false, nil, nil, msg
			end

			local weight = t.weight or "Regular"
			tmp.weight = weight
			valid, _ = verify_enum("FontWeight", weight)
			if valid then
				return_val.weight = weight
			else
				return_val.weight = "Regular"
				tmp.weight = "Regular"
			end

			local style = t.style or "Normal"
			tmp.style = style
			valid, _ = verify_enum("FontStyle", style)
			if valid then
				return_val.style = style
			else
				return_val.style = "Normal"
				tmp.style = "Normal"
			end
			return true, return_val, tmp
		end
		return false, nil, nil, "Font not Found"
	end,
	---@param t any?
	---@return boolean, boolean, {family: string, weight: string, style: string}?
	reverse = function(t)
		if type(t) ~= "table" or type(t.family) ~= "string" then
			return false, false, nil
		end

		local family = string.match(t.family, "^rbxasset://fonts/families/(.+)%.json$")

		if not family then
			return false, true, nil
		end

		return true, true, {
			family = family,
			weight = t.weight,
			style = t.style,
		}
	end,
}

roblox_types.Int32 = {
	lua_type = "number",
	fields = {
		"",
	},
	---@param t string
	---@return boolean, integer?
	verification = function(t)
		if handle_nil(t) then
			return true, nil
		end
		local i = tonumber(t)
		if i == nil then
			return false
		end
		return math.floor(i) == i, i
	end,
	---@param t any?
	---@return boolean, boolean, string?
	reverse = function(t)
		if type(t) ~= "number" then
			return false, false, nil
		end
		return true, true, tostring(t)
	end,
}

roblox_types.Int64 = {
	lua_type = "number",
	fields = {
		"",
	},
	---@param t string
	---@return boolean, integer?
	verification = function(t)
		if handle_nil(t) then
			return true, nil
		end
		local i = tonumber(t)
		if i == nil then
			return false
		end
		return math.floor(i) == i, i
	end,
	---@param t any?
	---@return boolean, boolean, string?
	reverse = function(t)
		if type(t) ~= "number" then
			return false, false, nil
		end
		return true, true, tostring(t)
	end,
}

roblox_types.NumberRange = {
	lua_type = "table",
	fields = {
		"Min",
		"Max",
	},
	---@param t {Min: string?, Max: string?}
	---@return boolean, number[]?, {Min: string, Max: string}?, string?
	verification = function(t)
		local min = tonumber(t.Min)
		local max = tonumber(t.Max)
		if min == nil or max == nil then
			return false, nil, nil, "Both Fields must contain a number"
		end
		if min > max then
			min, max = max, min
			t.Min, t.Max = tostring(max), tostring(min)
		end
		return true, { min, max }, { Min = tostring(min), Max = tostring(max) }
	end,
	---@param t any?
	---@return boolean, boolean, {Min: string, Max: string}?
	reverse = function(t)
		if type(t) ~= "table" then
			return false, false, nil
		end

		return true, true, { Min = tostring(t[1] or ""), Max = tostring(t[2] or "") }
	end,
}

roblox_types.NumberSequence = {
	lua_type = "nested table",
	fields = {
		"time",
		"value",
		"envelope",
	},
	---@param t {time: string?, value: string?, envelope: string?}[]
	---@return boolean, {keypoints: {time: number, value: number, envelope: number}[]}?, {time: string, value: string, envelope: string}[]?, string?
	verification = function(t)
		local tmp = vim.deepcopy(t)
		local return_val = {}
		for i, keypoint in ipairs(tmp) do
			local value = tonumber(keypoint.value)
			if value ~= nil then
				local time = tonumber(keypoint.time)
				if (not time) or time > 1 or time < 0 then
					return false, nil, nil, "Invalid at keypoint " .. i .. ", time must be a number in range [0, 1]"
				end
				local envelope = tonumber(keypoint.envelope) or 0.0
				table.insert(return_val, {
					time = time,
					value = value,
					envelope = envelope,
				})
				keypoint.envelope = tostring(envelope)
				keypoint.time = tostring(time)
			else
				return false, nil, nil, "Invalid at keypoint " .. i .. ", value field must contain a number"
			end
		end
		table.sort(return_val, function(a, b)
			return a.time < b.time
		end)
		table.sort(tmp, function(a, b)
			return tonumber(a.time) < tonumber(b.time)
		end)
		local msg
		if not #return_val >= 2 then
			msg = "Must have minimum of 2 keypoints"
		elseif not #return_val <= 20 then
			msg = "Cannot have more than 20 keypoints"
		elseif not return_val[1].time == 0.0 then
			msg = "At least one keypoint must have a time value of 0"
		elseif not return_val[#return_val].time == 1.0 then
			msg = "At least one keypoint must have a time value of 1.0"
		end
		return #return_val >= 2
			and #return_val <= 20
			and return_val[1].time == 0.0
			and return_val[#return_val].time == 1.0,
			{ keypoints = return_val },
			tmp,
			msg
	end,
	---@param t any?
	---@return boolean, boolean, {time: string, value: string, envelope: string}[]?
	reverse = function(t)
		if type(t) ~= "table" then
			return false, false, nil
		end

		local return_val = {}

		if type(t.keypoints) ~= "table" then
			return false, true, return_val
		end
		for _, keypoint in ipairs(t.keypoints) do
			if type(keypoint) == "table" then
				if type(keypoint.value) == "number" then
					table.insert(return_val, {
						time = tostring(type(keypoint.time) == "number" and keypoint.time or ""),
						value = tostring(keypoint.value),
						envelope = tostring(type(keypoint.envelope) == "number" and keypoint.envelope or ""),
					})
				end
			end
		end
		return true, true, return_val
	end,
}
local default_table = {
	density = "Default",
	friction = "Default",
	elasticity = "Default",
	frictionWeight = "Default",
	elasticityWeight = "Default",
	acousticAbsorption = "Default",
}

roblox_types.PhysicalProperties = {
	lua_type = "table",
	fields = {
		"density",
		"friction",
		"elasticity",
		"frictionWeight",
		"elasticityWeight",
		"acousticAbsorption",
	},
	---@param t {density: string?, friction: string?, elasticity: string?, frictionWeight: string?, elasticityWeight: string?, acousticAbsorption: string?}
	---@return boolean, table|string?, {density: string, friction: string, elasticity: string, frictionWeight: string, elasticityWeight: string, acousticAbsorption: string}?, string?
	verification = function(t)
		local tmp = vim.deepcopy(t)

		if next(t) == nil then
			return true, "Default", default_table
		end
		local return_val = {}
		local all_numbers = true
		for _, v in pairs(t) do
			if v == "Default" then
				return true, "Default", default_table
			elseif not tonumber(v) then
				all_numbers = false
			end
		end
		if not all_numbers then
			return false, nil, nil, "A field does not contain Default or a number"
		end
		return_val.density = clamp(t.density, 0.0001, 100.0, 0.5)
		tmp.density = tostring(return_val.density)
		return_val.friction = clamp(t.friction, 0.0, 2.0, 1.0)
		tmp.friction = tostring(return_val.friction)
		return_val.elasticity = clamp(t.elasticity, 0.0, 1.0, 0.0)
		tmp.elasticity = tostring(return_val.elasticity)
		return_val.frictionWeight = clamp(t.frictionWeight, 0.0, 100.0, 50.0)
		tmp.frictionWeight = tostring(return_val.frictionWeight)
		return_val.elasticityWeight = clamp(t.elasticityWeight, 0.0, 100.0, 25.0)
		tmp.elasticityWeight = tostring(return_val.elasticityWeight)
		return_val.acousticAbsorption = clamp(t.acousticAbsorption, 0.0, 1.0, 1.0)
		tmp.acousticAbsorption = tostring(return_val.acousticAbsorption)
		return true, return_val, tmp
	end,
	---@param t any?
	---@return boolean, boolean, {density: string, friction: string, elasticity: string, frictionWeight: string, elasticityWeight: string, acousticAbsorption: string}?
	reverse = function(t)
		if type(t) ~= "table" then
			if t == "Default" then
				return true, true, default_table
			end
			return false, false, nil
		end
		local return_val = {}

		return_val.density = tostring(tonumber(t.density) or "")
		return_val.friction = tostring(tonumber(t.friction) or "")
		return_val.elasticity = tostring(tonumber(t.elasticity) or "")
		return_val.frictionWeight = tostring(tonumber(t.frictionWeight) or "")
		return_val.elasticityWeight = tostring(tonumber(t.elasticityWeight) or "")
		return_val.acousticAbsorption = tostring(tonumber(t.acousticAbsorption) or "")

		return true, true, return_val
	end,
}

roblox_types.ProtectedString = {
	lua_type = "string",
	fields = {
		"",
	},
	---@param t string
	---@return boolean, string?
	verification = function(t)
		if type(t) == "string" then
			return string.len(t) > 0, t
		end
		return false, nil
	end,
	---@param t any?
	---@return boolean, boolean, string?
	reverse = function(t)
		if type(t) ~= "string" then
			return false, false, nil
		end
		return true, true, t
	end,
}

roblox_types.Ray = {
	lua_type = "table",
	fields = {
		"originX",
		"originY",
		"originZ",
		"directionX",
		"directionY",
		"directionZ",
	},
	---@param t {originX: string?, originY: string?, originZ: string?, directionX: string?, directionY: string?, directionZ: string?}
	---@return boolean, {origin: number[], direction: number[]}?, {originX: string?, originY: string?, originZ: string?, directionX: string?, directionY: string?, directionZ: string?}?, string?
	verification = function(t)
		local return_val = {}
		local verify
		verify, return_val.origin = verify_vector_3({ X = t.originX, Y = t.originY, Z = t.originZ })
		if not verify then
			return false, nil, nil, "All fields must contain a number"
		end
		verify, return_val.direction = verify_vector_3({ X = t.directionX, Y = t.directionY, Z = t.directionZ })
		if not verify then
			return false, nil, nil, "All fields must contain a number"
		end
		return true, return_val, t
	end,
	---@param t any?
	---@return boolean, boolean, {originX: string, originY: string, originZ: string, directionX: string, directionY: string, directionZ: string}?
	reverse = function(t)
		if type(t) ~= "table" then
			return false, false, nil
		end
		local return_val = {}

		if type(t.origin) == "table" and type(t.direction) == "table" then
			return_val.originX = tostring(tonumber(t.origin[1]) or "")
			return_val.originY = tostring(tonumber(t.origin[2]) or "")
			return_val.originZ = tostring(tonumber(t.origin[3]) or "")
			return_val.directionX = tostring(tonumber(t.direction[1]) or "")
			return_val.directionY = tostring(tonumber(t.direction[2]) or "")
			return_val.directionZ = tostring(tonumber(t.direction[3]) or "")
			return true, true, return_val
		end
		return false, true, return_val
	end,
}

roblox_types.Rect = {
	lua_type = "table",
	fields = {
		"X0",
		"Y0",
		"X1",
		"Y1",
	},
	---@param t {X0: string?, Y0: string?, X1: string?, Y1: string?}
	---@return boolean, number[][]?, {X0: string?, Y0: string?, X1: string?, Y1: string?}?, string?
	verification = function(t)
		local verify
		local corner0
		verify, corner0 = verify_vector_2({ X = t.X0, Y = t.Y0 })
		if not verify then
			return false, nil, nil, "All fields must contain a number"
		end
		local corner1
		verify, corner1 = verify_vector_2({ X = t.X1, Y = t.Y1 })
		if not verify then
			return false, nil, nil, "All fields must contain a number"
		end
		return true, { corner0, corner1 }, t
	end,
	---@param t any?
	---@return boolean, boolean, {X0: string, Y0: string, X1: string, Y1: string}?
	reverse = function(t)
		if type(t) ~= "table" then
			return false, false, nil
		end
		local return_val = {}

		if type(t[1]) == "table" and type(t[2]) == "table" then
			return_val.X0 = tostring(tonumber(t[1][1]) or "")
			return_val.Y0 = tostring(tonumber(t[1][2]) or "")
			return_val.X1 = tostring(tonumber(t[2][1]) or "")
			return_val.Y1 = tostring(tonumber(t[2][2]) or "")
			return true, true, return_val
		end
		return false, true, return_val
	end,
}

roblox_types.String = {
	lua_type = "string",
	fields = {
		"",
	},
	---@param t string
	---@return boolean, string?
	verification = function(t)
		if handle_nil(t) then
			return true, nil
		end
		if type(t) == "string" then
			return true, t
		end
		return false, nil
	end,
	---@param t any?
	---@return boolean, boolean, string?
	reverse = function(t)
		if type(t) ~= "string" then
			return false, false, nil
		end
		return true, true, t
	end,
}

roblox_types.UDim = {
	lua_type = "table",
	fields = {
		"Scale",
		"Offset",
	},
	---@param t {Scale: string?, Offset: string?}
	---@return boolean, number[]?, {Scale: string, Offset: string}?, string?
	verification = function(t)
		local return_val = {}
		local indexes = 0
		for k, i in pairs(t) do
			indexes = indexes + 1
			if tonumber(i) == nil then
				return false, nil, nil, "All fields must contain a number"
			end
			return_val[k] = tonumber(i)
		end
		if indexes == 2 then
			return_val = { return_val.Scale, return_val.Offset }
			return true, return_val, { Scale = tostring(return_val[1]), Offset = tostring(return_val[2]) }
		end
		return false, nil, nil, "All fields must contain a number"
	end,
	---@param t any?
	reverse = function(t)
		if type(t) ~= "table" then
			return false, false, nil
		end
		local return_val = {}

		return_val.Scale = tostring(tonumber(t[1]) or "")
		return_val.Offset = tostring(tonumber(t[2]) or "")
		return true, true, return_val
	end,
}

roblox_types.UDim2 = {
	lua_type = "table",
	fields = {
		"xScale",
		"xOffset",
		"yScale",
		"yOffset",
	},
	---@param t {xScale: string?, xOffset: string?, yScale: string?, yOffset: string?}
	---@return boolean, number[][]?, {xScale: string?, xOffset: string?, yScale: string?, yOffset: string?}?, string?
	verification = function(t)
		local return_val = {}
		local indexes = 0
		for k, i in pairs(t) do
			indexes = indexes + 1
			if tonumber(i) == nil then
				return false, nil, nil, "All fields must contain a number"
			end
			return_val[k] = tonumber(i)
		end
		if indexes == 4 then
			return_val = { { return_val.xScale, return_val.xOffset }, { return_val.yScale, return_val.yOffset } }
			return true, return_val, t
		end
		return false, nil, nil, "All fields must contain a number"
	end,
	---@param t any?
	---@return boolean, boolean, {xScale: string, xOffset: string, yScale: string, yOffset: string}?
	reverse = function(t)
		if type(t) ~= "table" then
			return false, false, nil
		end
		local return_val = {}
		if type(t[1]) == "table" and type(t[2]) == "table" then
			return_val.xScale = tostring(tonumber(t[1][1]) or "")
			return_val.xOffset = tostring(tonumber(t[1][2]) or "")
			return_val.yScale = tostring(tonumber(t[2][1]) or "")
			return_val.yOffset = tostring(tonumber(t[2][2]) or "")
			return true, true, return_val
		end
		return false, true, return_val
	end,
}

roblox_types.Vector2 = {
	lua_type = "table",
	fields = {
		"X",
		"Y",
	},
	---@param t { X: string?, Y: string?}
	---@return boolean, number[]?, {X: string?, Y: string?}, string?
	verification = function(t)
		return verify_vector_2(t)
	end,
	---@param t any?
	---@return boolean, boolean, {X: string, Y: string}?
	reverse = function(t)
		if type(t) ~= "table" then
			return false, false, nil
		end
		local return_val = {}
		return_val.X = tostring(tonumber(t[1]) or "")
		return_val.Y = tostring(tonumber(t[2]) or "")
		return true, true, return_val
	end,
}

roblox_types.Vector3 = {
	lua_type = "table",
	fields = {
		"X",
		"Y",
		"Z",
	},
	---@param t { X: string?, Y: string?, Z: string? }
	---@return boolean, number[]?, {X: string?, Y: string?, Z: string?}, string?
	verification = function(t)
		return verify_vector_3(t)
	end,
	---@param t any?
	---@return boolean, boolean, {X: string, Y: string, Z: string}?
	reverse = function(t)
		if type(t) ~= "table" then
			return false, false, nil
		end
		local return_val = {}
		return_val.X = tostring(tonumber(t[1]) or "")
		return_val.Y = tostring(tonumber(t[2]) or "")
		return_val.Z = tostring(tonumber(t[3]) or "")
		return true, true, return_val
	end,
}

---@param class string
---@param json_data table
---@return { [string]: {json: any?, value: any?} }?
local function revert(class, json_data)
	local class_def = data.raw.Classes[class]
	if not class_def then
		vim.notify("Class '" .. class .. "' is not supported", vim.log.levels.ERROR)
		return nil
	end
	local return_val = {}
	for n, d in pairs(json_data.Properties or json_data.properties or {}) do
		return_val[n] = {}
		local t, value = next(d)
		if t ~= nil and value ~= nil then
			return_val[n].json = d
			if roblox_types[t] then
				local success, valid_type, v
				local enum_name
				if t == "Enum" then
					enum_name = class_def.Properties[n].ValueType.Name
					success, valid_type, v = roblox_types[t].reverse(enum_name, value)
				end
				success, valid_type, v = roblox_types[t].reverse(value)

				local json_table, valid_value
				if success or valid_type then
					if t == "Enum" then
						roblox_types[t].verification(enum_name, v)
					elseif type(value) == "table" then
						success, json_table, valid_value = roblox_types[t].verification(v)
						return_val[n].value = success and valid_value or v
						return_val[n].json = success and json_table and { [t] = json_table } or return_val[n].json
					elseif t == "Enum" then
						roblox_types[t].verification(enum_name, v)
					else
						success, json_table = roblox_types[t].verification(v)
						return_val[n].value = success and v or nil
						return_val[n].json = success and json_table and { [t] = json_table } or return_val[n].json
					end
				elseif not valid_type then
					return_val[n].json = nil -- This is confirmed to not be valid by the current definition of the Roblox and Rojo APIs
				end
			end
		end
	end
	return return_val
end

roblox_types.convert = revert

return roblox_types
