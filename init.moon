-- -*- MoonScript -*-

local *

------------------------------------------------------------
-- * Parameters
------------------------------------------------------------

WAYPOINT_SCHEDULE = {
    'new', 'new', 'new',
    'old',
    'new', 'old', 'old',
    'new', 'old', 'old', 'old', 'old',
    'new', 'old', 'old', 'old', 'old', 'old',
    'new', 'old', 'old', 'old', 'old', 'old', 'old',
    'new', 'old', 'old', 'old', 'old', 'old', 'old', 'old'}

-- Time-limit parameters are in seconds.
STARTING_TIME_LIMIT = 2 * 60
NEW_WAYPOINT_TIME_BONUS = 1 * 60
OLD_WAYPOINT_TIME_BONUS = .5 * 60

START_TIMEOFDAY = 6 / 24  -- simulated days
END_TIMEOFDAY = (12 + 6) / 24  -- simulated days
CYCLE_MINS = .5 -- real minutes to go from START_TIMEOFDAY to END_TIMEOFDAY

gen_waypoint_distance = -> math.random 50, 300

------------------------------------------------------------
-- * Constants
------------------------------------------------------------

MAX_LIGHT = 15
NOON = .5

sp = nil
minetest.register_on_joinplayer (player) ->
    sp = minetest.get_player_by_name 'singleplayer'

------------------------------------------------------------
-- * Subroutines
------------------------------------------------------------

msg = (text) ->
    minetest.chat_send_player 'singleplayer', text, false

randelm = (l) ->
    l[math.random #l]

p3 = (x, y, z) -> {:x, :y, :z}
origin = p3 0, 0, 0

posplus = (pos1, pos2) ->
    {x: pos1.x + pos2.x, y: pos1.y + pos2.y, z: pos1.z + pos2.z}

poseq = (pos1, pos2) ->
    pos1.x == pos2.x and pos1.y == pos2.y and pos1.z == pos2.z

dist_xz = (pos1, pos2) ->
-- Distance as the crow flies
    math.sqrt (pos1.x - pos2.x)^2 + (pos1.z - pos2.z)^2

yaw_to = (pos1, pos2) ->
-- Yaw in radians [0, 2π) from pos1 to pos2, with 0 in the
-- positive z-direction and π/2 in the negative x-direction.
-- This deliberately imitates the yaw reading in the F5 debug
-- screen.
--         
--        0
--        z+
--             
-- π/2 x-     x+
--
--        z-
--
    v = math.atan2 pos1.x - pos2.x, pos2.z - pos1.z
    if v < 0 then v + 2*math.pi else v

sp_yaw = -> (sp\get_look_yaw! - math.pi/2) % (2 * math.pi)
-- The player's yaw, in the same format as yaw_to.

yaw_diff = (yaw1, yaw2) ->
-- Radians (-π, π) needed to turn yaw1 to match yaw2. Positive is
-- left and negative is right.
    diff = yaw2 - yaw1
    if diff > math.pi
        diff - 2*math.pi
    elseif diff < -math.pi
        2*math.pi + diff
    else
        diff

time_limit = STARTING_TIME_LIMIT
time_left = -> time_limit - minetest.get_gametime!

fmt_time_diff = (diff) ->
    if diff > 0
        '%d:%02d'\format math.floor(diff/60), diff % 60
    else
        "---"

------------------------------------------------------------
-- * Setup
------------------------------------------------------------

recycle_timeofday = ->
    minetest.set_timeofday START_TIMEOFDAY
    minetest.after 60*CYCLE_MINS, recycle_timeofday

game_state = 'init'
setup = ->
    minetest.setting_set 'time_speed',
        (END_TIMEOFDAY - START_TIMEOFDAY) / (CYCLE_MINS / (60*24))
      -- This sets the speed of time such that CYCLE_MINS minutes
      -- of real time will take the world exactly from
      -- START_TIMEOFDAY to END_TIMEOFDAY.
    recycle_timeofday!
    sp\set_physics_override do
       4, -- run speed
       1.5, -- jump height
       1, -- gravity
       true, -- can the player sneak?
       true  -- can the player use the sneak glitch? (what is that?)
    inv = sp\get_inventory!
    inv\add_item 'main', 'default:pick_steel'
    inv\add_item 'main', 'default:axe_steel'
    inv\add_item 'main', 'default:shovel_steel'
    inv\add_item 'main', 'default:sign_wall 10'
    game_state = 'playing'
minetest.after 2, setup

------------------------------------------------------------
-- * Waypoints
------------------------------------------------------------

waypoints = {}
current_waypoint = nil
marked_waypoint = nil
waypoints_visited = 0
unique_waypoints_visited = 0
minetest.register_on_mapgen_init (mgparams) ->
    if #waypoints == 0
        math.randomseed mgparams.seed
        x, z = 0, 0
        waypoints = for n = 1, #[1 for w in *WAYPOINT_SCHEDULE when w == 'new']
            distance = gen_waypoint_distance!
            angle = math.random! * 2*math.pi
            x += math.floor distance * math.cos angle
            z += math.floor distance * math.sin angle
            {
                :n
                created: false
                spawner: false
                  -- 'spawner' is set to a particle spawner that
                  -- makes the waypoint visible.
                found: false
                ymin: -1/0    -- negative infinity
                ymax: 1/0   -- positive infinity
                pos: {:x, :z}}
        current_waypoint = waypoints[1]
        marked_waypoint = current_waypoint

-- Create waypoints as the map is generated. The x- and
-- z-coordinates are chosen in advance, but the y-coordinates are
-- chosen based on the terrain such that waypoints are always on
-- the ground.
minetest.register_on_generated (minp, maxp, blockseed) ->
    for wp in *waypoints
        if not wp.created and do
                wp.pos.x >= minp.x and wp.pos.x <= maxp.x and do
                wp.pos.z >= minp.z and wp.pos.z <= maxp.z
            for y = minp.y, maxp.y
                here = {x: wp.pos.x, y: y, z: wp.pos.z}
                if minetest.get_node_light(here, NOON) == MAX_LIGHT or do
                        minetest.get_node(here).name == 'default:water_source'
                    wp.ymax = math.min wp.ymax, y - 1
                else
                    wp.ymin = math.max wp.ymin, y
            if wp.ymin >= wp.ymax
                wp.pos.y = wp.ymin
                if wp == current_waypoint 
                    wp.spawner = mk_waypoint_spawner wp.pos
                wp.created = true

minetest.register_on_punchnode (pos, node, puncher) ->
    if puncher == sp and current_waypoint and game_state == 'playing' and do
            current_waypoint.created and poseq pos, current_waypoint.pos
        msg "You found waypoint #{current_waypoint.n}."
        waypoints_visited += 1
        unless current_waypoint.found
            unique_waypoints_visited += 1
            current_waypoint.found = true
        if current_waypoint.spawner
         -- This waypoint will no longer be current, so remove
         -- its spawner.
            minetest.delete_particlespawner current_waypoint.spawner
            current_waypoint.spawner = false
        if waypoints_visited < #WAYPOINT_SCHEDULE
            if WAYPOINT_SCHEDULE[waypoints_visited + 1] == 'new'
              -- Activate the next waypoint and mark it.
                current_waypoint = waypoints[unique_waypoints_visited + 1]
                marked_waypoint = current_waypoint
                if marked_waypoint.created
                    marked_waypoint.spawner = mk_waypoint_spawner marked_waypoint.pos
                time_limit += NEW_WAYPOINT_TIME_BONUS
                msg "Now find the NEW waypoint #{current_waypoint.n}."
            else
              -- Activate a random previously found waypoint (other than the current one),
              -- but don't mark it.
                current_waypoint = randelm do
                    [w for w in *waypoints when w.found and w != current_waypoint]
                marked_waypoint = nil
                time_limit += OLD_WAYPOINT_TIME_BONUS
                msg "Now find the OLD waypoint #{current_waypoint.n}."
        else
            game_state = 'won'
            current_waypoint = nil
            marked_waypoint = nil
            msg 'You completed the whole schedule. Not too shabby!'

mk_waypoint_spawner = (wp_pos) -> minetest.add_particlespawner do
    1, -- particles / second
    0, -- lifespan (infinite)
    wp_pos, -- min. position
    wp_pos, -- max. position
    p3 0, 1, 0, -- min. velocity
    p3 0, 3, 0, -- max. velocity
    origin, origin, -- min. / max. acceleration
    3, 3, -- min. / max. lifetime
    5, 5, -- min. / max. size
    false, -- collides with objects?
    'default_nc_rb.png' -- texture (set to Nyan Cat Rainbow)

------------------------------------------------------------
-- * HUD
------------------------------------------------------------

hud_elem = nil

setup_hud = ->
    hud_elem = sp\hud_add
        hud_elem_type: 'text'
        position: {x: 0.2, y: 0.9}
        scale: {x: 100, y: 100}
        alignment: {x: 0, y: -1}
        number: 0xffffff --color
        text: ''
minetest.after 2, setup_hud

update_hud = (dtime) ->
    if hud_elem
        sp\hud_change hud_elem, 'text', hud_f!
minetest.register_globalstep update_hud

hud_f = ->
    local tl
    if game_state == 'playing'
        tl = time_left!
        if tl <= 0
            game_state = 'lost'
            msg "Sorry; you're out of time."
    "Found: %d unique, %d total\n%s"\format do
        unique_waypoints_visited,
        waypoints_visited,
        if game_state == 'playing'
            "Time left: %s\nNext: %d (%s)"\format do
                fmt_time_diff tl,
                current_waypoint.n,
                if marked_waypoint
                    dist_and_dir sp\getpos!, marked_waypoint.pos, sp_yaw!
                else
                    'old'
        elseif game_state == 'init'
           'Starting the game...'
        else
           'Game Over'

dist_and_dir = (pos1, pos2, yaw1) ->
-- Returns a string like "030 m, <<< 046 deg" describing the
-- distance (along the X-Z plane) and rotation needed to get from
-- pos1 to pos2.
    dir = do
        deg = math.deg yaw_diff yaw1, yaw_to pos1, pos2
        if math.abs(deg) < 1
            'ahead'
        else if math.abs(deg) > 134
            'behind'
        else
            '%s %02.0f deg'\format do
                if deg < 0 then '>>>' else '<<<',
                math.abs(deg)
    distance = do
        m = dist_xz pos1, pos2
        if m < 1000
            '%03.0f m'\format m
        else
            '%1.2f km'\format m/1000
    '%s, %s'\format distance, dir
