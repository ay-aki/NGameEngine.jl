



intround      = (x -> Int(round(x)))
intfloor      = (x -> Int(floor(x)))
intceil       = (x -> Int(ceil(x)))
uint8round    = (x -> UInt8(round(x)))
uint8round255 = (x -> UInt8(round(x*255)))
rot_2d_matrix(θ::Real) = [cos(θ) -sin(θ); sin(θ) cos(θ)]



get_list_positions() = [:topleft, :topcenter, :topright, :leftcenter, :center, :rightcenter, :bottomleft, :bottomcenter, :bottomright]


get_list_positionals() = [:top, :bottom, :left, :right]




"""
# get_dx_to_topleft
```
dx = get_dx_to_topleft(:bottomcenter, w)
x += dx
```
"""
get_dx_to_topleft(s::Symbol, w) = begin
    if     s == :topleft      ret =   [0     , 0     ]
    elseif s == :topcenter    ret = - [w[1]÷2, 0     ]
    elseif s == :topright     ret = - [w[1]  , 0     ]
    elseif s == :leftcenter   ret = - [ 0    , w[2]÷2]
    elseif s == :center       ret = - [w[1]÷2, w[2]÷2]
    elseif s == :rightcenter  ret = - [w[1]  , w[2]÷2]
    elseif s == :bottomleft   ret = - [ 0    , w[2]  ]
    elseif s == :bottomcenter ret = - [w[1]÷2, w[2]  ]
    elseif s == :bottomright  ret = - [w[1]  , w[2]  ]
    else                      @error("NGE: get_dx_to_topleft")
    end
    return ret
end

get_dx_from_topleft(w, s::Symbol) = begin
    if     s == :topleft      ret =  [0       , 0       ]
    elseif s == :topcenter    ret =  [w[1]÷2-1, 0       ]
    elseif s == :topright     ret =  [w[1]-1  , 0       ]
    elseif s == :leftcenter   ret =  [0       , w[2]÷2-1]
    elseif s == :center       ret =  [w[1]÷2-1, w[2]÷2-1]
    elseif s == :rightcenter  ret =  [w[1]-1  , w[2]÷2-1]
    elseif s == :bottomleft   ret =  [0       , w[2]-1  ]
    elseif s == :bottomcenter ret =  [w[1]÷2-1, w[2]-1  ]
    elseif s == :bottomright  ret =  [w[1]-1  , w[2]-1  ]
    else                      @error("NGE: get_dx_from_topleft")
    end
    return ret
end

get_positionals(val, s::Symbol) = begin
    if     s == :left   return val.topleft[1]
    elseif s == :top    return val.topleft[2]
    elseif s == :right  return val.bottomright[1]
    elseif s == :bottom return val.bottomright[2]
    end
end

set_positionals!(val, s::Symbol, a) = begin
    if     s == :top
        topleft     = val.topleft
        val.topleft = [topleft[1], a]
    elseif s == :left 
        topleft     = val.topleft
        val.topleft = [a, topleft[2]]
    elseif s == :bottom
        bottomleft     = val.bottomleft
        val.bottomleft = [bottomleft[1], a]
    elseif s == :right
        bottomright     = val.bottomright
        val.bottomright = [a, bottomright[2]]
    else
        @error("NGE: error in set_positionals!")
    end
end

r_to_2dim(r) = (typeof(r) <: Real) ? [r, r] : r

function surface_to_texture(surface)
    texture = sdl_create_texture_from_surface(renderer, surface)
    sdl_free_surface(surface)
    push!(reserve_destroy, texture)
    w, h = sdl_query_texture(texture)
    return texture, Rect([0, 0], [w, h]), Rect([0, 0], [w, h])
end

function make_get_id()
    id = 0
    get_id() = (id = id + 1; id)
    return get_id
end
global get_id
get_id = make_get_id()

new_dict() = Dict{Symbol, Union{Real, AbstractArray}}()
