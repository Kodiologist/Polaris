-- -*- MoonScript -*-

export *
--local *

MAX_LIGHT = 15
NOON = .5

NUM_WAYPOINTS = 3
VISIT_GOAL = NUM_WAYPOINTS + 1

sp = nil
minetest.register_on_joinplayer (player) ->
    sp = minetest.get_player_by_name 'singleplayer'

------------------------------------------------------------
-- * Subroutines
------------------------------------------------------------

msg = (text) ->
    minetest.chat_send_player 'singleplayer', text, false

coinflip = -> math.random() > .5

p3 = (x, y, z) -> {:x, :y, :z}
origin = p3 0, 0, 0

posplus = (pos1, pos2) ->
    {x: pos1.x + pos2.x, y: pos1.y + pos2.y, z: pos1.z + pos2.z}

poseq = (pos1, pos2) ->
    pos1.x == pos2.x and pos1.y == pos2.y and pos1.z == pos2.z

dist_xz = (pos1, pos2) ->
-- Distance as the crow flies
    math.sqrt (pos1.x - pos2.x)^2 + (pos1.z - pos2.z)^2

rad2deg = (radians) -> 180/math.pi * radians

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

------------------------------------------------------------
-- * Setup
------------------------------------------------------------

setup = ->
    sp\set_physics_override 4, -- run speed
       1.5, -- jump height
       1, -- gravity
       true, -- can the player sneak?
       true  -- can the player use the sneak glitch? (what is that?)
    inv = sp\get_inventory!
    inv\add_item 'main', 'default:pick_steel'
    inv\add_item 'main', 'default:axe_steel'
    inv\add_item 'main', 'default:shovel_steel'
    inv\add_item 'main', 'default:torch 10'
    inv\add_item 'main', 'default:sign_wall 10'
minetest.after 2, setup

------------------------------------------------------------
-- * Waypoints
------------------------------------------------------------

waypoints = {}
current_waypoint = nil
marked_waypoint = nil
waypoints_visited = 0
minetest.register_on_mapgen_init (mgparams) ->
    if #waypoints == 0
        math.randomseed mgparams.seed
        waypoints = for n = 1, NUM_WAYPOINTS
           {n: n,
            created: false,
            spawner: false,
              -- 'spawner' is set to a particle spawner that
              -- makes the waypoint visible.
            ymin: -1/0,    -- negative infinity
            ymax: 1/0,   -- positive infinity
            pos: {
                x: (if coinflip! then 1 else -1) * math.random(100, 200),
                z: (if coinflip! then 1 else -1) * math.random(100, 200)}}
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
                    wp.ymax = math.min wp.ymax, y
                else
                    wp.ymin = math.max wp.ymin, y + 1
            if wp.ymin >= wp.ymax
                wp.pos.y = wp.ymin
                if wp == current_waypoint 
                    wp.spawner = mk_waypoint_spawner wp.pos
                wp.created = true

minetest.register_on_punchnode (pos, node, puncher) ->
    if puncher == sp and current_waypoint and current_waypoint.created and do
            poseq pos, posplus(current_waypoint.pos, p3 0, -1, 0)
        msg "You found waypoint #{current_waypoint.n}."
        waypoints_visited += 1
        if current_waypoint.spawner
         -- This waypoint will no longer be current, so remove
         -- its spawner.
            minetest.delete_particlespawner current_waypoint.spawner
            current_waypoint.spawner = false
        if waypoints_visited < NUM_WAYPOINTS
          -- Activate the next waypoint and mark it.
            current_waypoint = waypoints[current_waypoint.n % NUM_WAYPOINTS + 1]
            marked_waypoint = current_waypoint
            if marked_waypoint.created
                marked_waypoint.spawner = mk_waypoint_spawner marked_waypoint.pos
        elseif waypoints_visited < VISIT_GOAL
          -- Activate the next waypoint, but don't mark it.
            current_waypoint = waypoints[current_waypoint.n % NUM_WAYPOINTS + 1]
            marked_waypoint = nil
        else
            msg 'You win!'
            current_waypoint = nil
            marked_waypoint = nil
        if current_waypoint
            msg "Now find waypoint #{current_waypoint.n}."

mk_waypoint_spawner = (wp_pos) -> minetest.add_particlespawner .25, -- particles / second
    0, -- lifespan (infinite)
    posplus wp_pos, p3 -.5, -.5, -.5, -- min. position
    posplus wp_pos, p3 .5, .5, .5, -- max. position
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
    hud_elem = sp\hud_add {
        hud_elem_type: 'text',
        position: {x: 0.2, y: 0.9},
        scale: {x: 100, y: 100},
        alignment: {x: 0, y: -1},
        number: 0xffffff, --color
        text: ''}
minetest.after 2, setup_hud

update_hud = (dtime) ->
    if hud_elem
        sp\hud_change hud_elem, 'text', hud_f!
minetest.register_globalstep update_hud

hud_f = ->
    if marked_waypoint
        'Next: ' .. dist_and_dir sp\getpos!, marked_waypoint.pos, sp_yaw!
    else
        ''

dist_and_dir = (pos1, pos2, yaw1) ->
-- Returns a string like "030 m, <<< 046 deg" describing the
-- distance (along the X-Z plane) and rotation needed to get from
-- pos1 to pos2.
    dir = do
        deg = rad2deg yaw_diff yaw1, yaw_to pos1, pos2
        if math.abs(deg) < 1
            'ahead'
        else if math.abs(deg) > 134
            'behind'
        else
            string.format '%s %02.0f deg',
                (if deg < 0 then '>>>' else '<<<'),
                math.abs(deg)
    distance = do
        m = dist_xz pos1, pos2
        if m < 1000
            string.format '%03.0f m', m
        else
            string.format '%1.2f km', m/1000
    string.format '%s, %s', distance, dir
