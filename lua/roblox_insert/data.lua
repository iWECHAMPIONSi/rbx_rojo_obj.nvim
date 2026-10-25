local t = {}
local vim = vim

local category_keys = require("roblox_insert.category_data")

local function get_plugin_root()
	local source = debug.getinfo(1, "S").source:gsub("^@", "")

	local module_directory = assert(vim.fs.dirname(source), "Unable to locate roblox_insert module directory")

	local lua_directory = assert(vim.fs.dirname(module_directory), "Unable to locate the plugin's lua directory")

	return assert(vim.fs.dirname(lua_directory), "Unable to locate the plugin root directory")
end

---@param path string
---@return string?, string?
local function read_file(path, filename)
	local file, open_error = io.open(path, "rb")

	if file == nil then
		return nil, string.format("Attempt to open " .. filename .. ".json failed: %s", tostring(open_error))
	end

	local contents = file:read("*a")

	if contents == nil then
		file:close()

		return nil, string.format("Attempt to read " .. filename .. ".json failed: %s", path)
	end

	local close_success, close_error = file:close()

	if close_success == nil then
		return nil, string.format("Attempt to close " .. filename .. ".json failed: %s", tostring(close_error))
	end

	return contents, nil
end

local function save_data(filename, data)
	local code = vim.json.encode(data)
	local path = vim.fs.joinpath(vim.fn.stdpath("state"), "rbx_rojo_obj")
	if not vim.uv.fs_stat(path) then
		vim.fn.mkdir(path, "p")
	end

	path = vim.fs.joinpath(path, filename .. ".json")

	local file = io.open(path, "w")

	if file then
		file:write(code)
		file:close()
	else
		vim.notify("Failed to save data.", vim.log.levels.ERROR)
	end
end

---@return table?, string?
function t.load(filename, save_path, absolute_path)
	local path = absolute_path
		or vim.fs.joinpath(save_path or get_plugin_root(), save_path and "rbx_rojo_obj" or "data", filename .. ".json")

	local contents, read_error = read_file(path, filename)

	if contents == nil then
		return nil, read_error
	end

	local decode_success, decoded = pcall(vim.json.decode, contents)

	if not decode_success then
		return nil,
			string.format("Could not decode Roblox class " .. filename .. " file '%s': %s", path, tostring(decoded))
	end

	if type(decoded) ~= "table" then
		return nil, string.format("Roblox class " .. filename .. " file '%s' did not contain a JSON object", path)
	end
	return decoded, nil
end

local raw, raw_err = t.load("data")

local favorites, favorites_err = t.load("favorites", vim.fn.stdpath("state"))

t.favorites = favorites or {}
t.favorites_err = favorites_err

t.raw = {}
t.err = raw_err

if not raw then
	return t
end

t.raw.Classes, t.raw.Enums = raw.Classes, raw.Enums

for _, v in pairs(t.raw.Classes) do
	local properties = {}
	for k, _ in pairs(v.Properties) do
		table.insert(properties, k)
	end
	table.sort(properties)
	v.PropertyKeys = properties
end

local iter_table = {}

local tempkeys = {}
local permkeys = {}

for name, _ in pairs(raw.Classes) do
	tempkeys[name] = true
end

local cat = nil
local super = nil
local classes = nil

local to_remove = {}

for _, category in ipairs(category_keys) do
	cat = category.Category
	iter_table[cat] = {}
	table.insert(permkeys, cat)
	super = category.Superclasses
	for _, class in ipairs(super) do
		for name, _ in pairs(tempkeys) do
			for _, superclass in ipairs(raw.Classes[name].NestedClasses) do
				if superclass == class then
					table.insert(iter_table[cat], name)
					table.insert(to_remove, name)
					break
				end
			end
		end
		for _, name in ipairs(to_remove) do
			tempkeys[name] = nil
		end
		to_remove = {}
	end
	classes = category.Classes
	for _, class in ipairs(classes) do
		table.insert(iter_table[cat], class)
		for name, _ in pairs(tempkeys) do
			if name == class then
				table.insert(to_remove, name)
			end
		end
	end
	for _, name in ipairs(to_remove) do
		tempkeys[name] = nil
	end
	to_remove = {}
	table.sort(iter_table[cat], function(a, b)
		return a < b
	end)
end

t.categories = iter_table
t.catkeys = permkeys

for class, _ in pairs(t.favorites) do
	table.insert(t.categories["Favorites"], class)
end

table.sort(t.categories)

local browsable_classes = {
	Accessory = true,
	AccessoryDescription = true,
	Actor = true,
	AdGui = true,
	AirController = true,
	AlignOrientation = true,
	AlignPosition = true,
	AngularVelocity = true,
	Animation = true,
	AnimationConstraint = true,
	AnimationController = true,
	Animator = true,
	ArcHandles = true,
	Atmosphere = true,
	AtmosphereSensor = true,
	Attachment = true,
	AudioAnalyzer = true,
	AudioChannelMixer = true,
	AudioChannelSplitter = true,
	AudioChorus = true,
	AudioCompressor = true,
	AudioDeviceInput = true,
	AudioDeviceOutput = true,
	AudioDistortion = true,
	AudioEcho = true,
	AudioEmitter = true,
	AudioEqualizer = true,
	AudioFader = true,
	AudioFilter = true,
	AudioFlanger = true,
	AudioGate = true,
	AudioLimiter = true,
	AudioListener = true,
	AudioPitchShifter = true,
	AudioPlayer = true,
	AudioReverb = true,
	AudioSpeechToText = true,
	AudioTextToSpeech = true,
	AudioTremolo = true,
	BallSocketConstraint = true,
	Beam = true,
	BillboardGui = true,
	BindableEvent = true,
	BindableFunction = true,
	BloomEffect = true,
	BlurEffect = true,
	BodyColors = true,
	BodyPartDescription = true,
	Bone = true,
	BoolValue = true,
	BoxHandleAdornment = true,
	BrickColorValue = true,
	BuoyancySensor = true,
	CFrameValue = true,
	Camera = true,
	CanvasGroup = true,
	ChorusSoundEffect = true,
	ClickDetector = true,
	ClimbController = true,
	Clouds = true,
	Color3Value = true,
	ColorCorrectionEffect = true,
	ColorGradingEffect = true,
	CompressorSoundEffect = true,
	ConeHandleAdornment = true,
	Configuration = true,
	ControllerManager = true,
	ControllerPartSensor = true,
	CornerWedgePart = true,
	CylinderHandleAdornment = true,
	CylindricalConstraint = true,
	DebugClass = true,
	Decal = true,
	DepthOfFieldEffect = true,
	Dialog = true,
	DialogChoice = true,
	DistortionSoundEffect = true,
	DragDetector = true,
	EchoSoundEffect = true,
	EqualizerSoundEffect = true,
	Explosion = true,
	FaceControls = true,
	Fire = true,
	FlangeSoundEffect = true,
	FluidForceSensor = true,
	Folder = true,
	ForceField = true,
	Frame = true,
	GeneratedFolder = true,
	GroundController = true,
	Handles = true,
	HapticEffect = true,
	Highlight = true,
	HingeConstraint = true,
	Humanoid = true,
	HumanoidDescription = true,
	HumanoidRigDescription = true,
	IKControl = true,
	ImageButton = true,
	ImageHandleAdornment = true,
	ImageLabel = true,
	InputAction = true,
	InputActionLabel = true,
	InputBinding = true,
	InputContext = true,
	IntValue = true,
	LineForce = true,
	LineHandleAdornment = true,
	LinearVelocity = true,
	LocalScript = true,
	LocalizationTable = true,
	MakeupDescription = true,
	MaterialVariant = true,
	Model = true,
	ModuleScript = true,
	Motor = true,
	Motor6D = true,
	NoCollisionConstraint = true,
	NumberValue = true,
	ObjectValue = true,
	Pants = true,
	Part = true,
	ParticleEmitter = true,
	Path2D = true,
	PathfindingLink = true,
	PathfindingModifier = true,
	PitchShiftSoundEffect = true,
	PlaneConstraint = true,
	PointLight = true,
	PrismaticConstraint = true,
	ProceduralModel = true,
	ProximityPrompt = true,
	PyramidHandleAdornment = true,
	RayValue = true,
	RelativeGui = true,
	RemoteEvent = true,
	RemoteFunction = true,
	ReverbSoundEffect = true,
	RigidConstraint = true,
	RodConstraint = true,
	RopeConstraint = true,
	ScreenGui = true,
	Script = true,
	ScrollingFrame = true,
	Seat = true,
	SelectionBox = true,
	SelectionSphere = true,
	Shirt = true,
	ShirtGraphic = true,
	Sky = true,
	Smoke = true,
	Sound = true,
	SoundGroup = true,
	Sparkles = true,
	SpawnLocation = true,
	SphereHandleAdornment = true,
	SpotLight = true,
	SpringConstraint = true,
	StringValue = true,
	StyleDerive = true,
	StyleLink = true,
	StyleQuery = true,
	StyleRule = true,
	StyleSheet = true,
	SunRaysEffect = true,
	SurfaceAppearance = true,
	SurfaceGui = true,
	SurfaceLight = true,
	SurfaceSelection = true,
	SwimController = true,
	Team = true,
	TextBox = true,
	TextButton = true,
	TextChannel = true,
	TextChatCommand = true,
	TextLabel = true,
	Texture = true,
	Tool = true,
	Torque = true,
	TorsionSpringConstraint = true,
	Trail = true,
	TremoloSoundEffect = true,
	TrussPart = true,
	UIAspectRatioConstraint = true,
	UICorner = true,
	UIDragDetector = true,
	UIFlexItem = true,
	UIGradient = true,
	UIGridLayout = true,
	UIListLayout = true,
	UIPadding = true,
	UIPageLayout = true,
	UIScale = true,
	UIShadow = true,
	UISizeConstraint = true,
	UIStroke = true,
	UITableLayout = true,
	UITextSizeConstraint = true,
	UniversalConstraint = true,
	UnreliableRemoteEvent = true,
	Vector3Value = true,
	VectorForce = true,
	VehicleSeat = true,
	VideoFrame = true,
	ViewportCamera = true,
	ViewportFrame = true,
	WedgePart = true,
	Weld = true,
	WeldConstraint = true,
	Wire = true,
	WireframeHandleAdornment = true,
	WorldModel = true,
}

local non_browsable_classes = {
	AdPortal = true,
	AdvancedDragger = true,
	AnimationNodeDefinition = true,
	AnimationRigData = true,
	Backpack = true,
	CompositeValueCurve = true,
	DataStoreGetOptions = true,
	DataStoreIncrementOptions = true,
	DataStoreOptions = true,
	DataStoreSetOptions = true,
	DigitsRigDescription = true,
	Dragger = true,
	EulerRotationCurve = true,
	ExperienceInviteOptions = true,
	FloatCurve = true,
	Keyframe = true,
	KeyframeMarker = true,
	MarkerCurve = true,
	RenderingTest = true,
	RotationCurve = true,
	StarterGear = true,
	TeleportOptions = true,
	TextGenerator = true,
	ValueCurve = true,
	Vector3Curve = true,
}

local browsable_categories = {
	["Favorites"] = true,
	["3D Interfaces"] = true,
	["Adornments"] = true,
	["Ads"] = true,
	["Animations"] = true,
	["Avatar"] = true,
	["Constraints"] = true,
	["Effects"] = true,
	["Environment"] = true,
	["GUI"] = true,
	["Input"] = true,
	["Interaction"] = true,
	["Lights"] = true,
	["Localization"] = true,
	["Parts"] = true,
	["Post Processing Effects"] = true,
	["Scripting"] = true,
	["Sensors"] = true,
	["Sounds"] = true,
	["Styling"] = true,
	["Text Chat"] = true,
	["Uncategorized"] = true,
	["Values"] = true,
	["World"] = true,
}

local non_browsable_categories = {
	["AnimationInfo"] = true,
	["Backpack"] = true,
	["Controllers"] = true,
	["Data Store"] = true,
	["Dragger"] = true,
	["Other"] = true,
	["Posing"] = true,
	["Text Chat Properties"] = true,
}

t.non_browsable_categories = non_browsable_categories

t.browsable_categories = browsable_categories

t.browsable_classes = browsable_classes
t.non_browsable_classes = non_browsable_classes

local function toggle_favorite(class)
	if t.favorites[class] then
		t.favorites[class] = nil
		for i, c in ipairs(t.categories["Favorites"]) do
			if c == class then
				table.remove(t.categories["Favorites"], i)
				break
			end
		end
		save_data("favorites", t.favorites)
		return
	end
	t.favorites[class] = true

	table.insert(t.categories["Favorites"], class)
	table.sort(t.categories["Favorites"])
	save_data("favorites", t.favorites)
end

t.toggle_favorite = toggle_favorite

local entries = {
	{ "White", 1 },
	{ "Grey", 2 },
	{ "Light yellow", 3 },
	{ "Brick yellow", 5 },
	{ "Light green (Mint)", 6 },
	{ "Light reddish violet", 9 },
	{ "Pastel Blue", 11 },
	{ "Light orange brown", 12 },
	{ "Nougat", 18 },
	{ "Bright red", 21 },
	{ "Med. reddish violet", 22 },
	{ "Bright blue", 23 },
	{ "Bright yellow", 24 },
	{ "Earth orange", 25 },
	{ "Black", 26 },
	{ "Dark grey", 27 },
	{ "Dark green", 28 },
	{ "Medium green", 29 },
	{ "Lig. Yellowich orange", 36 },
	{ "Bright green", 37 },
	{ "Dark orange", 38 },
	{ "Light bluish violet", 39 },
	{ "Transparent", 40 },
	{ "Tr. Red", 41 },
	{ "Tr. Lg blue", 42 },
	{ "Tr. Blue", 43 },
	{ "Tr. Yellow", 44 },
	{ "Light blue", 45 },
	{ "Tr. Flu. Reddish orange", 47 },
	{ "Tr. Green", 48 },
	{ "Tr. Flu. Green", 49 },
	{ "Phosph. White", 50 },
	{ "Light red", 100 },
	{ "Medium red", 101 },
	{ "Medium blue", 102 },
	{ "Light grey", 103 },
	{ "Bright violet", 104 },
	{ "Br. yellowish orange", 105 },
	{ "Bright orange", 106 },
	{ "Bright bluish green", 107 },
	{ "Earth yellow", 108 },
	{ "Bright bluish violet", 110 },
	{ "Tr. Brown", 111 },
	{ "Medium bluish violet", 112 },
	{ "Tr. Medi. reddish violet", 113 },
	{ "Med. yellowish green", 115 },
	{ "Med. bluish green", 116 },
	{ "Light bluish green", 118 },
	{ "Br. yellowish green", 119 },
	{ "Lig. yellowish green", 120 },
	{ "Med. yellowish orange", 121 },
	{ "Br. reddish orange", 123 },
	{ "Bright reddish violet", 124 },
	{ "Light orange", 125 },
	{ "Tr. Bright bluish violet", 126 },
	{ "Gold", 127 },
	{ "Dark nougat", 128 },
	{ "Silver", 131 },
	{ "Neon orange", 133 },
	{ "Neon green", 134 },
	{ "Sand blue", 135 },
	{ "Sand violet", 136 },
	{ "Medium orange", 137 },
	{ "Sand yellow", 138 },
	{ "Earth blue", 140 },
	{ "Earth green", 141 },
	{ "Tr. Flu. Blue", 143 },
	{ "Sand blue metallic", 145 },
	{ "Sand violet metallic", 146 },
	{ "Sand yellow metallic", 147 },
	{ "Dark grey metallic", 148 },
	{ "Black metallic", 149 },
	{ "Light grey metallic", 150 },
	{ "Sand green", 151 },
	{ "Sand red", 153 },
	{ "Dark red", 154 },
	{ "Tr. Flu. Yellow", 157 },
	{ "Tr. Flu. Red", 158 },
	{ "Gun metallic", 168 },
	{ "Red flip/flop", 176 },
	{ "Yellow flip/flop", 178 },
	{ "Silver flip/flop", 179 },
	{ "Curry", 180 },
	{ "Fire Yellow", 190 },
	{ "Flame yellowish orange", 191 },
	{ "Reddish brown", 192 },
	{ "Flame reddish orange", 193 },
	{ "Medium stone grey", 194 },
	{ "Royal blue", 195 },
	{ "Dark Royal blue", 196 },
	{ "Bright reddish lilac", 198 },
	{ "Dark stone grey", 199 },
	{ "Lemon metalic", 200 },
	{ "Light stone grey", 208 },
	{ "Dark Curry", 209 },
	{ "Faded green", 210 },
	{ "Turquoise", 211 },
	{ "Light Royal blue", 212 },
	{ "Medium Royal blue", 213 },
	{ "Rust", 216 },
	{ "Brown", 217 },
	{ "Reddish lilac", 218 },
	{ "Lilac", 219 },
	{ "Light lilac", 220 },
	{ "Bright purple", 221 },
	{ "Light purple", 222 },
	{ "Light pink", 223 },
	{ "Light brick yellow", 224 },
	{ "Warm yellowish orange", 225 },
	{ "Cool yellow", 226 },
	{ "Dove blue", 232 },
	{ "Medium lilac", 268 },
	{ "Slime green", 301 },
	{ "Smoky grey", 302 },
	{ "Dark blue", 303 },
	{ "Parsley green", 304 },
	{ "Steel blue", 305 },
	{ "Storm blue", 306 },
	{ "Lapis", 307 },
	{ "Dark indigo", 308 },
	{ "Sea green", 309 },
	{ "Shamrock", 310 },
	{ "Fossil", 311 },
	{ "Mulberry", 312 },
	{ "Forest green", 313 },
	{ "Cadet blue", 314 },
	{ "Electric blue", 315 },
	{ "Eggplant", 316 },
	{ "Moss", 317 },
	{ "Artichoke", 318 },
	{ "Sage green", 319 },
	{ "Ghost grey", 320 },
	{ "Lilac", 321 },
	{ "Plum", 322 },
	{ "Olivine", 323 },
	{ "Laurel green", 324 },
	{ "Quill grey", 325 },
	{ "Crimson", 327 },
	{ "Mint", 328 },
	{ "Baby blue", 329 },
	{ "Carnation pink", 330 },
	{ "Persimmon", 331 },
	{ "Maroon", 332 },
	{ "Gold", 333 },
	{ "Daisy orange", 334 },
	{ "Pearl", 335 },
	{ "Fog", 336 },
	{ "Salmon", 337 },
	{ "Terra Cotta", 338 },
	{ "Cocoa", 339 },
	{ "Wheat", 340 },
	{ "Buttermilk", 341 },
	{ "Mauve", 342 },
	{ "Sunrise", 343 },
	{ "Tawny", 344 },
	{ "Rust", 345 },
	{ "Cashmere", 346 },
	{ "Khaki", 347 },
	{ "Lily white", 348 },
	{ "Seashell", 349 },
	{ "Burgundy", 350 },
	{ "Cork", 351 },
	{ "Burlap", 352 },
	{ "Beige", 353 },
	{ "Oyster", 354 },
	{ "Pine Cone", 355 },
	{ "Fawn brown", 356 },
	{ "Hurricane grey", 357 },
	{ "Cloudy grey", 358 },
	{ "Linen", 359 },
	{ "Copper", 360 },
	{ "Medium brown", 361 },
	{ "Bronze", 362 },
	{ "Flint", 363 },
	{ "Dark taupe", 364 },
	{ "Burnt Sienna", 365 },
	{ "Institutional white", 1001 },
	{ "Mid gray", 1002 },
	{ "Really black", 1003 },
	{ "Really red", 1004 },
	{ "Deep orange", 1005 },
	{ "Alder", 1006 },
	{ "Dusty Rose", 1007 },
	{ "Olive", 1008 },
	{ "New Yeller", 1009 },
	{ "Really blue", 1010 },
	{ "Navy blue", 1011 },
	{ "Deep blue", 1012 },
	{ "Cyan", 1013 },
	{ "CGA brown", 1014 },
	{ "Magenta", 1015 },
	{ "Pink", 1016 },
	{ "Deep orange", 1017 },
	{ "Teal", 1018 },
	{ "Toothpaste", 1019 },
	{ "Lime green", 1020 },
	{ "Camo", 1021 },
	{ "Grime", 1022 },
	{ "Lavender", 1023 },
	{ "Pastel light blue", 1024 },
	{ "Pastel orange", 1025 },
	{ "Pastel violet", 1026 },
	{ "Pastel blue-green", 1027 },
	{ "Pastel green", 1028 },
	{ "Pastel yellow", 1029 },
	{ "Pastel brown", 1030 },
	{ "Royal purple", 1031 },
	{ "Hot pink", 1032 },
}

local colors = {}
for _, entry in ipairs(entries) do
	local name, number = entry[1], entry[2]
	colors[number] = name
	if colors[name] == nil then
		colors[name] = number
	end
end

t.colors = colors

local saved_configs, _ = t.load("class_configs", vim.fn.stdpath("state"))

t.saved_object_configs = saved_configs or {}

for k, _ in pairs(t.browsable_classes) do
	t.saved_object_configs[k] = t.saved_object_configs[k] or { property_tables = {} }
end

for k, _ in pairs(t.non_browsable_classes) do
	t.saved_object_configs[k] = t.saved_object_configs[k] or { property_tables = {} }
end

local function save_object_configs()
	local tmp = vim.deepcopy(t.saved_object_configs)
	for k, i in pairs(tmp) do
		for index, p in ipairs(i.property_tables) do
			if not p.name then
				table.remove(i.property_tables, index)
				break
			end
		end
		if #i.property_tables == 0 then
			tmp[k] = nil
		else
			i.index = nil
		end
	end
	save_data("class_configs", tmp)
end

t.save_object_configs = save_object_configs

return t
