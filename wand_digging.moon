
local *

WAND_RANGE = 20

PLAYER_HEIGHT = 1 + 10/16

p3 = (x, y, z) -> {:x, :y, :z}
origin = p3 0, 0, 0

posplus = (pos1, pos2) ->
    {x: pos1.x + pos2.x, y: pos1.y + pos2.y, z: pos1.z + pos2.z}

posm = (scale, pos) ->
    {x: scale * pos.x, y: scale * pos.y, z: scale * pos.z}

round = (x) -> math.floor x + .5

roundpos = (pos) ->
    {x: round(pos.x), y: round(pos.y), z: round(pos.z)}

one_to_left = (v) -> p3 do
    -v.z / math.sqrt v.z^2 + v.x^2,
    v.y,
    v.x / math.sqrt v.z^2 + v.x^2

one_to_right = (v) -> p3 do
    v.z / math.sqrt v.z^2 + v.x^2,
    v.y,
    -v.x / math.sqrt v.z^2 + v.x^2

one_up = (v) ->
    l1 = math.sqrt v.z^2 + v.x^2
    l2 = math.sqrt v.z^2 + v.y^2 + v.x^2
    {x: -v.x*v.y / (l1 * l2), y: l1 / l2, z: -v.y*v.z / (l1 * l2)}

one_down = (v) -> posm -1, one_up v

adjust_pos = (pos, dir, h, v) ->
    if h > 0 then pos = posplus pos, posm h, one_to_left dir
    if h < 0 then pos = posplus pos, posm math.abs(h), one_to_right dir
    if v > 0 then pos = posplus pos, posm v, one_up dir
    if v < 0 then pos = posplus pos, posm math.abs(v), one_down dir
    pos

-- Finding the upper point x2, y2, z2:
--  - Length, as usual, is 1
--  - Necessarily, y2 >= y1
--     (y2 == y1 iff the player is looking straight up or down)
--
--             z
--             |  /
--             | /
--      ---------------- x
---            |
---            |

--    z = m*x
--  - Thus: x2 / z2 == x1 / z1

minetest.register_craftitem 'polaris:wand_digging',
    description: 'Wand of Digging'
    inventory_image: 'bucket.png'
    on_use: (itemstack, user, pointed_thing) ->
        dir = posm .5, user\get_look_dir!
        pos = posplus user\getpos!, p3 0, PLAYER_HEIGHT, 0
        pos = posplus pos, posm 2, dir
        rays = [adjust_pos pos, dir, h, v for h = -1, 1 for v = -1, 1]
        for n = 1, 2*WAND_RANGE
            for i, r in ipairs rays
                minetest.remove_node roundpos r
                rays[i] = posplus r, dir
        -- The wand is used up.
        itemstack\take_item!
        return itemstack
