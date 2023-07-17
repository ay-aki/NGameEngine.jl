



# print(@__DIR__)

intround      = (x -> Int(round(x)))
intfloor      = (x -> Int(floor(x)))
intceil       = (x -> Int(ceil(x)))
uint8round    = (x -> UInt8(round(x)))
uint8round255 = (x -> UInt8(round(x*255)))
rot_2d_matrix(θ::Real) = [cos(θ) -sin(θ); sin(θ) cos(θ)]


#=

"""
# s_to_topleft
s_to_topleft(s::Symbol, x::AbstractArray, w::AbstractArray) 
"""
s_to_topleft(s::Symbol, x::AbstractArray, w::AbstractArray) = begin
    if     s == :topleft      topleft = x
    elseif s == :topcenter    topleft = x - [w[1]÷2, 0     ]
    elseif s == :topright     topleft = x - [w[1]  , 0     ]
    elseif s == :leftcenter   topleft = x - [ 0    , w[2]÷2]
    elseif s == :center       topleft = x - [w[1]÷2, w[2]÷2]
    elseif s == :rightcenter  topleft = x - [w[1]  , w[2]÷2]
    elseif s == :bottomleft   topleft = x - [ 0    , w[2]  ]
    elseif s == :bottomcenter topleft = x - [w[1]÷2, w[2]  ]
    elseif s == :bottomright  topleft = x - [w[1]  , w[2]  ]
    end
    return topleft
end


"""
# topleft_to_s
topleft_to_s(topleft::AbstractArray, w, s) 
"""
topleft_to_s(topleft::AbstractArray, w, s) = begin
    if     s == :topleft      ret = topleft
    elseif s == :topcenter    ret = topleft + [w[1]÷2-1, 0       ]
    elseif s == :topright     ret = topleft + [w[1]-1  , 0       ]
    elseif s == :leftcenter   ret = topleft + [0       , w[2]÷2-1]
    elseif s == :center       ret = topleft + [w[1]÷2-1, w[2]÷2-1]
    elseif s == :rightcenter  ret = topleft + [w[1]-1  , w[2]÷2-1]
    elseif s == :bottomleft   ret = topleft + [0       , w[2]-1  ]
    elseif s == :bottomcenter ret = topleft + [w[1]÷2-1, w[2]-1  ]
    elseif s == :bottomright  ret = topleft + [w[1]-1  , w[2]-1  ]
    end
    return ret
end



function get_list_positions()
    [:topleft, :topcenter, :topright, :leftcenter, :center, :rightcenter, :bottomleft, :bottomcenter, :bottomright]
end

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
=#

