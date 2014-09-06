# Set up the world
WIDTH = window.innerWidth
HEIGHT = window.innerHeight

main = d3.select('#main')
    .attr
        width: WIDTH
        height: HEIGHT

FRICTION = 0.998
GRAVITY = 0.8
BOUNCE = 0.7
MIN_V = 0.1

# Getter shortcut attr('attrname', obj)
attr = h.curry (a, o) -> o[a]

# Create a random entity
randomEnt = ->
    x: WIDTH * Math.random()
    y: HEIGHT * Math.random()
    r: 50 * Math.random() + 5
    v:
        x: 10 * Math.random() - 5
        y: 10 * Math.random() - 5

N = 10
ents = [0..N].map(randomEnt)

# Set up circle elements
circles = main.selectAll('circle')
    .data(ents)
circles.enter().append('circle')
    .attr('fill', '#333')

render = ->
    circles
        .attr('cx', attr 'x')
        .attr('cy', attr 'y')
        .attr('r', attr 'r')
    # Light up binked circles
    circles.filter((d) -> d.binked)
        .attr('fill', '#cef')
        .transition()
            .attr('fill', '#333')
        # Set back to unbinked
        .each (d) -> d.binked = false

# Change position and velocity per tick
pos = (ent) ->
    # Try sticking to the bottom
    if Math.abs(ent.v.y) <= GRAVITY && (ent.y + ent.r + 2) > HEIGHT
        ent.v.y = 0
        ent.v.x *= FRICTION
    # p = p + v
    ent.x += ent.v.x
    ent.y += ent.v.y
    # v = v + a
    ent.v.y += GRAVITY
    return ent

# Collide with the walls
col = (ent) ->
    # If the bottom is below the window bottom while going down
    if ent.v.y > 0 && (ent.y + ent.r) > HEIGHT
        ent.v.y *= -1 * BOUNCE * (1 - 1/ent.r)
    # If the left is past window left while going left
    else if ent.v.x < 0 && (ent.x - ent.r) < 0
        ent.v.x *= -1 * BOUNCE * (1 - 1/ent.r)
    # If the right is past window right while going right
    else if ent.v.x > 0 && (ent.x + ent.r) > WIDTH
        ent.v.x *= -1 * BOUNCE * (1 - 1/ent.r)
    return ent

tick = ->
    ents.map(pos).map(col)
    render()

setInterval tick, 20

# Bink a circle
bink = h.curry (i, v) ->
    ents[i].v.y -= v/3.0
    ents[i].binked = true

[0..N].map (i) ->
    eventStream('midi', "nanoPAD2:#{ 36 + i }:on")
        .each bink i

eventStream('midi', "nanoKONTROL2:23")
    .each (v) ->
        GRAVITY = v * 3 - 0.5
