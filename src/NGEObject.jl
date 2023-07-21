

global list_font_loaded, list_image_loaded
list_font_loaded = []
list_image_loaded = []





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


"""
# Font
"""
mutable struct Font id; file; font end
export Font
function Font(file::String = samplefiles.nge.NotoSansJP)
    for ft in list_font_loaded
        if file == ft.file 
            return ft 
        end
    end
    font = ttf_open_font(file)
    if Int(font) == 0  error("NGE: ttf error can't read a font file") 
    end
    ttf_set_font_hinting(font)
    push!(reserve_close, font)
    _font_ = Font(get_id(), file, font)
    push!(list_font_loaded, _font_)
    return _font_
end

"""
# Empty
"""
mutable struct Empty end
export Empty

"""
# Line
"""
mutable struct Line x; vec; _dict_ end
export Line
Line(vec = [100, 100]) = Line([0, 0], vec, new_dict())

"""
# Rect
"""
mutable struct Rect x; w; _dict_ end
export Rect
Rect(w = [100, 100]) = Rect([0, 0], w, new_dict())
Rect(x, w) = Rect(x, w, new_dict())

"""
# Circle
"""
mutable struct Circle o; r; _dict_ end
export Circle
Circle(r = 50) = Circle([0, 0], r, new_dict())

"""
# Donut
"""
mutable struct Donut o; r; r0; _dict_ end
export Donut
Donut(r = [50, 50], r0 = [25, 25]) = Donut([0, 0], r_to_2dim(r), r_to_2dim(r0), new_dict())

"""
# Ellipse
"""
mutable struct Ellipse o; r; _dict_ end
export Ellipse
Ellipse(r = [50, 30]) = Ellipse([0, 0], r_to_2dim(r), new_dict())

"""
# Pattern
"""
mutable struct Pattern x; X; _dict_ end
export Pattern
Pattern(X = [true]) = Pattern([0, 0], X, new_dict())

"""
# Texture
"""
mutable struct Texture id; texture; rect0::Rect; rect::Rect end
export Texture
Texture(args...) = Texture(get_id(), args...)
Base.copy(tex::Texture) = Texture(tex.id, tex.texture, tex.rect0, tex.rect)

"""
# Image
"""
mutable struct Image file; tex::Texture; _dict_ end
export Image
function Image(file = samplefiles.nge.sample0)
    for img in list_image_loaded
        if file == img.file  return img end
    end
    surface = img_load(file)
    texture, rect0, rect = surface_to_texture(surface)
    _img_ = Image(file, Texture(texture, rect0, rect), new_dict())
    push!(list_image_loaded, _img_)
    return _img_
end
Base.copy(img::Image) = Image("", copy(img.tex), img._dict_)

"""
# Moji
"""
mutable struct Moji str; font; tex::Texture; _dict_ end
export Moji
function Moji(str = "Hello", font = Font(); color = RGBA(1, 1, 1, 1))
    surface = ttf_render_UTF8_blanded(font.font, str, color)
    texture, rect0, rect = surface_to_texture(surface)
    return Moji(str, font, Texture(texture, rect0, rect), new_dict())
end
Base.copy(moji::Moji) = Moji(moji.str, moji.font, copy(moji.tex), moji._dict_)




Geometry = Union{Empty, Line, Rect, Circle, Donut, Ellipse, Pattern, Image, Moji}






get_bound(val::Rect) = val.w
get_bound(val::Union{Image, Moji}) = val.tex.rect.w
get_bound(val::Circle) = 2 * val.r * ones(Integer, 2)
get_bound(val::Donut) = 2 * val.r .* ones(Integer, 2)
get_bound(val::Ellipse) = 2 * val.r .* ones(Integer, 2)
get_bound(val::Line) = begin
    w = Int.(round.(val.vec))
end
#[max(val.x[1], val.y[1]), max(val.x[2], val.y[2])]


get_x(val::Union{Rect, Line, Pattern}) = getfield(val, :x)
get_x(val::Union{Circle, Donut, Ellipse}) = val.o .- val.r
get_x(val::Union{Image, Moji}) = val.tex.rect.x



set_x!(val::Union{Line, Rect, Pattern}, x) = begin
    setfield!(val, :x, x)
end
set_x!(val::Union{Circle, Donut, Ellipse}, x) = begin
    val.o = x .+ val.r
end
set_x!(val::Union{Image, Moji}, x) = begin
    val.tex.rect.x = x
end



function Base.getproperty(val::Geometry, name::Symbol)
    if name == :x
        return get_x(val)
    elseif name in get_list_positions()
        return val.x + get_dx_from_topleft(get_bound(val), name)
    elseif name in get_list_positionals() # アクセスだけ可能
        return get_positionals(val, name)
    elseif name in keys(getfield(val, :_dict_))
        return val._dict_[name]
    else
        return getfield(val, name)
    end
end
# 
function Base.setproperty!(val::Geometry, name::Symbol, a)
    if name == :x
        set_x!(val, a)
    elseif name in get_list_positions()
        val.x = a + get_dx_to_topleft(name, get_bound(val))
    elseif name in get_list_positionals()
        set_positionals!(val, name, a)
    elseif name in fieldnames(typeof(val))
        setfield!(val, name, a)
    else
        val._dict_[name] = a
    end
end





"""
# Grid
gridの中にオブジェクトを入れると、勝手に座標が書き換えられる。
"""
mutable struct Grid w; siz; offset; obj::Matrix{Geometry} end
export Grid
function Grid(w=[32,32], siz=[20,15]; offset=[0,0])
    obj = Matrix{Geometry}(undef, siz[1], siz[2])#fill(Geometry(), Tuple(siz))
    n, m = siz
    for i = 1:n  for j = 1:m
        rect = (Rect(w))
        rect.x = offset + ([i, j] .- 1) .* w
        obj[i, j] = rect
    end end
    return Grid(w, siz, offset, obj)
end
Base.getindex(gr::Grid, i::Int, j::Int) = gr.obj[i, j]
function Base.getindex(gr::Grid, ii::AbstractVector{Int64}, jj::AbstractVector{Int64})
    offset = gr.offset + gr.w .* [ii[1], jj[1]]
    siz = length.([ii, jj])
    obj = gr.obj[ii, jj]
    newgr =  Grid(gr.w, siz, offset, obj)
    return newgr
end
function Base.collect(gr::Grid)
    n, m = gr.siz
    A = fill(gr[1, 1], (n, m))
    for i = 1:n for j = 1:m
        A[i, j] = gr[i, j]
    end end
    return A
end
Base.size(gr::Grid, d::Integer) = gr.siz[d]
Base.size(gr::Grid) = (size(gr, 1), size(gr, 2))
function Base.setindex!(gr::Grid, val, i::Integer, j::Integer)
    val.x = gr.offset + ([i, j] .- 1) .* gr.w
    gr.obj[i, j] = val
end
function Base.setindex!(gr::Grid, val::Matrix, ii::AbstractVector{Int64}, jj::AbstractVector{Int64})
    n, m = size(gr)
    for i = 1:n for j = 1:m
        gr[i, j] = val[i, j]
    end end
end
function Base.setindex!(gr::Grid, val, i::Colon, j::Colon)
    n, m = size(gr)
    gr[1:n, 1:m] .= val
end





# Boundary Shape Transformation

Rect(rect::Rect) = rect
Rect(val::Union{Line, Circle, Donut, Ellipse, Image, Moji}) = begin 
    rect = Rect(get_bound(val))
    rect.x = val.x
    return rect
end

Circle(circle::Circle) = circle
Circle(val::Union{Donut, Ellipse}) = begin # 囲む円
    circle   = Circle(max(val.r[1], val.r[2]))
    circle.o = val.o
    return circle
end



