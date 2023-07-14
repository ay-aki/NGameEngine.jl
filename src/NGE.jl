module NGE

include("./NGESDL.jl")
include("./NGEAssets.jl")

using .NGESDL
using Colors, LinearAlgebra

export norm, kron

global section, win, renderer, event_ref, events, t0, t_old

global reserve_close
reserve_close = [] # close all

global reserve_destroy
reserve_destroy = [] # destroy all

global samplefiles 
samplefiles = SampleFiles()

global global_list_font_loaded
global_list_font_loaded = []


include("./NGEApp.jl")


# print(@__DIR__)

intround      = (x -> Int(round(x)))
intfloor      = (x -> Int(floor(x)))
intceil       = (x -> Int(ceil(x)))
uint8round    = (x -> UInt8(round(x)))
uint8round255 = (x -> UInt8(round(x*255)))
rot_2d_matrix(θ::Real) = [cos(θ) -sin(θ); sin(θ) cos(θ)]




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
end










"""
# Tf
移動や回転、色の変更を与える。 \\
カラー属性は２つを掛け合わせると消失する。\\
"""
mutable struct Tf
    a::AbstractArray
    θ::Real
    c::Union{AbstractRGBA, DataType}
    w::Union{AbstractArray, DataType}
    Tf(tf::Tf) = Tf(a=tf.a, θ=tf.θ, c=tf.c, w=tf.w)
    function Tf(
        ; a = 1.0 # scaling param
        , θ = 0.0 # [radian]
        , c = Nothing
        , w = Nothing # resize param
    )
        if typeof(a) <: Real  a = [a, a]
        end
        return new(a, θ, c, w)
    end
end
export Tf
Base.copy(tf::Tf) = Tf(tf)
function Base.:*(tf1::Tf, tf2::Tf)
    return Tf(
        a = tf1.a + tf2.a, 
        θ = tf1.θ + tf2.θ
    )
end











"""
# AbstractType Geometry
Line, Circle, Rectangle, Pattern, EmptyGeom
"""
abstract type Geometry end



"""
# EmptyGeom
空のオブジェクト実体 \\
サイズのベクトルを持っている
"""
struct EmptyGeom <: Geometry
    w::AbstractArray
    EmptyGeom(eg::EmptyGeom) = new(eg.w)
    function EmptyGeom(
        w = [32, 32]
    )
        return new(w)
    end
end
export EmptyGeom
Base.copy(eg::EmptyGeom) = EmptyGeom(eg)



"""
# Line
## 説明
線オブジェクト \\
## how to use
```
line = Line([10, 50]) # 線の作成
```
"""
struct Line <: Geometry
    v::AbstractArray
    w::AbstractArray
    Line(line::Line) = new(line.v, line.w)
    function Line(
        v = [100, 100]
    )
        w = abs.(v)
        return new(v, w)
    end
end
export Line
Base.copy(line::Line) = Line(line)



"""
# Circle
円、楕円、ドーナツ型オブジェクト \\
circle = Circle() #半径50の縁を生成 \\
"""
struct Circle <: Geometry
    r::AbstractArray
    r0::AbstractArray
    θ::Real
    w::AbstractArray
    Circle(circle::Circle) = new(circle.r, circle.r0, circle.θ, circle.w)
    function Circle(r = 50, r0 = r, θ = 0)
        if typeof(r)  <: Real  r  = [r, r]
        end
        if typeof(r0) <: Real  r0 = [r0, r0]
        end
        w = 2 * r # require fix
        return new(r, r0, θ, w)
    end
end
export Circle
Base.copy(circle::Circle) = Circle(circle)



"""
# Rectangle
"""
struct Rectangle <: Geometry
    w::AbstractArray
    Rectangle(rect::Rectangle) = new(rect.w)
    function Rectangle(w = [100, 100])
        return new(w)
    end
end
export Rectangle
Base.copy(rect::Rectangle) = Circle(rect)



"""
# Pattern
"""
struct Pattern <: Geometry
    X::Matrix{Bool}
    w::AbstractArray
    Pattern(pat::Pattern) = Pattern(X=pat.X)
    function Pattern(X = [true])
        w = collect(size(X))
        return new(X, w)
    end
end
export Pattern



"""
# Font
"""
struct Font
    file::AbstractString
    font
    Font(font::Font) = Font(file=font.file) # あんまり意味ない
    function Font(file = samplefiles.nge.assets.ttf_files.NotoSansJP)
        for ft in global_list_font_loaded
            if file == ft.file
                return ft
            end
        end
        font = ttf_open_font(file)
        push!(reserve_close, font)
        if Int(font) == 0  error("NGE: ttf error can't read a font file") 
        end
        _font_ = new(file, font)
        push!(global_list_font_loaded, _font_)
        return _font_
    end
end
export Font











"""
# Texture
Moji, Image <: Texture
"""
abstract type Texture end



"""
# Moji
文字を扱う。
"""
mutable struct Moji <: Texture
    str::AbstractString
    x0::AbstractArray
    w0::AbstractArray
    w::AbstractArray
    texture
    Moji(moji::Moji) = new(moji.str, moji.x0, moji.w0, moji.w, moji.texture)
    function Moji(str = "Hello World !", font = Font(); color = RGBA(1, 1, 1, 1))
        surface = ttf_render_UTF8_blanded(font.font, str, color)
        texture = sdl_create_texture_from_surface(renderer, surface)
        sdl_free_surface(surface)
        push!(reserve_destroy, texture)
        w1, w2 = sdl_query_texture(texture)
        x0 = [0 , 0 ]
        w0 = [w1, w2]
        w  = [w1, w2]
        return new(str, x0, w0, w, texture)
    end
end
export Moji
Base.copy(moji::Moji) = Moji(moji)



# 多重読み込みに弱い
"""
# Image
画像を扱う
"""
mutable struct Image <: Texture
    file::AbstractString
    x0::AbstractArray
    w0::AbstractArray
    w::AbstractArray
    texture
    Image(img::Image) = new("", img.x0, img.w0, img.w, img.texture)
    function Image(file = samplefiles.nge.assets.img_files.sample0)
        surface = img_load(file)
        texture = sdl_create_texture_from_surface(renderer, surface)
        sdl_free_surface(surface)
        push!(reserve_destroy, texture)
        w, h = sdl_query_texture(texture)
        return new(file, [0, 0], [w, h], [w, h], texture)
    end
end
export Image
Base.copy(img::Image) = Image(img)










"""
# Object
位置情報などを含むオブジェクト \\
pinの実装がまだ(pinはオブジェクトと座標xの関係をピン止めする)
"""
mutable struct Object
    obj::Union{Geometry, Texture}
    x::AbstractArray
    c::Union{AbstractArray, AbstractRGBA}
    pin::Symbol
    _dict_::Dict
    Object(scene::Scene) = Object(EmptyGeom(scene.w))
    Object(object::Object) = new(object.obj, object.x, obj)
    function Object(obj::Union{Geometry, Texture})
        x = [0.0, 0.0]
        c = RGBA(1, 1, 1, 1)
        pin = :topleft
        d = Dict{Symbol, Union{Real, AbstractArray}}(:_copy_x_ => copy(x))
        return new(obj, x, c, pin, d)
    end
end
export Object
function Base.getproperty(object::Object, s::Symbol)
    try 
        return getfield(object, s)
    catch 
        if (! (object._dict_[:_copy_x_] == object.x))
            for s = [:top, :bottom, :left, :right]
                delete!(object._dict_, s)
            end
            for s = [:topleft, :topcenter, :topright, :leftcenter, :center, :rightcenter, :bottomleft, :bottomcenter, :bottomright]
                delete!(object._dict_, s)
            end
            object._dict_[:_copy_x_] = object.x
        end
        try
            return object._dict_[s]
        catch
            if s in [:top, :bottom, :left, :right]
                if     s == :left   object.left = object.topleft[1]
                elseif s == :top    object.top  = object.topleft[2]
                elseif s == :right  object.right = object.bottomright[1]
                elseif s == :bottom object.bottom = object.bottomright[2]
                end
                return getproperty(object, s)
            end
            if s in [:topleft, :topcenter, :topright, :leftcenter, :center, :rightcenter, :bottomleft, :bottomcenter, :bottomright]
                try
                    topleft = object._dict_[:topleft]
                    object._dict_[s] = topleft_to_s(topleft, object.obj.w, s)
                catch
                    topleft = s_to_topleft(object.pin, object.x, object.obj.w)
                    object.topleft = topleft
                    object._dict_[s] = topleft_to_s(topleft, object.obj.w, s)
                end
                return getproperty(object, s)
            end
        end
    end
end
function Base.setproperty!(object::Object, s::Symbol, val)
    try
        setfield!(object, s, val)
    catch
        object._dict_[s] = val
    end
end








"""
# Grid
"""
mutable struct Grid
    w::AbstractArray
    offset::AbstractArray
    siz::AbstractArray
    object::Matrix{Object}
    # is_valid::Matrix{Bool} # 禁止 objectの辞書を使う
    Grid(w, offset, siz, object) = new(w, offset, siz, object)#, is_valid)
    function Grid(
          w        = [32, 32]
        , siz      = [20, 15]
        ; object   = fill(Object(EmptyGeom(w)), Tuple(siz))
        , offset   = [0, 0]
        # , is_valid = ones(Bool, siz[1], siz[2])
    )
        for i = 1:siz[1] for j = 1:siz[2]
            x = offset + ([i, j] .- 1) .* w
            object[i, j].x = x
        end end
        return new(w, offset, siz, object)# , is_valid)
    end
end
export Grid
Base.getindex(gr::Grid, i::Int, j::Int) = gr.object[i, j]
function Base.getindex(gr::Grid, ii::AbstractVector{Int64}, jj::AbstractVector{Int64})
    w = gr.w
    offset = gr.offset + w .* [ii[1], jj[1]]
    siz = length.([ii, jj])
    object = gr.object[ii, jj]
    # is_valid = gr.is_valid[ii, jj]
    newgr =  Grid(w, offset, siz, object)# , is_valid)
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
function Base.setindex!(gr::Grid, val::Object, i::Integer, j::Integer)
    val.x = gr.offset + ([i, j] .- 1) .* gr.w
    gr.object[i, j] = val
end
function Base.setindex!(gr::Grid, val::Object, ii::AbstractVector{Int64}, jj::AbstractVector{Int64})
    n, m = size(gr)
    for i = 1:n for j = 1:m
        gr[i, j] = val
    end end
end
function Base.setindex!(gr::Grid, val::Matrix{Object}, ii::AbstractVector{Int64}, jj::AbstractVector{Int64})
    n, m = size(gr)
    for i = 1:n for j = 1:m
        gr[i, j] = val[i, j]
    end end
end
function Base.setindex!(gr::Grid, val, i::Colon, j::Colon)
    n, m = size(gr)
    gr[1:n, 1:m] .= val
end













#=
接触判定オブジェクト
=#
function each_intersects!(matview, object::Object, v::AbstractArray)
    left , upper = object.topleft .< v
    right, lower = v .< object.bottomright
    matview .&= [
        left & upper  right & upper; 
        left & lower  right & lower
    ]
end
function map_intersects(object::Object, b_object::Object)
    ret = ones(Bool, 3, 3)
    each_intersects!(view(ret, 1:2, 1:2), object, b_object.topleft)
    each_intersects!(view(ret, 1:2, 2:3), object, b_object.topright)
    each_intersects!(view(ret, 2:3, 1:2), object, b_object.bottomleft)
    each_intersects!(view(ret, 2:3, 2:3), object, b_object.bottomright)
    return ret
end
function intersectsmat_to_s(t, s::Symbol)
    if     s == :top
        return all(t[1:2, 2])
    elseif s == :bottom
        return all(t[2:3, 2])
    elseif s == :left
        return all(t[2, 1:2])
    elseif s == :right 
        return all(t[2, 2:3])
    elseif s == :bounded
        return t[2,2] & (sum(t) == 1)
    elseif s == :bounds 
        return all(t)
    end
    @error("Intersects creation failed")
end
"""
# Intersects(object, b_object)
"""
mutable struct Intersects
    object::Object
    b_object::Object
    _mat_::Matrix{Bool}
    _dict_::Dict
    function Intersects(object, b_object)
        _mat_  = map_intersects(object, b_object)
        _dict_ = Dict{Symbol, Union{Real, AbstractArray}}()
        return new(object, b_object, _mat_, _dict_)
    end
end
export Intersects
function Base.getproperty(it::Intersects, s::Symbol)
    try
        return getfield(it, s)
    catch
        try
            return it._dict_[s]
        catch
            if s in [:top, :bottom, :left, :right, :bounded, :bounds]
                it._dict_[s] = intersectsmat_to_s(it._mat_, s)
            end
            return getproperty(it, s)
        end
    end
end
function Base.any(it::Intersects)
    return it.top | it.bottom | it.left | it.right
end














"""
# draw functions 
以下のように用いる。\\
`draw(Object::TYPE <: Union{Geometry, Texture}, vpos, color = color, ...)`
## how to use 
draw(c = RGBA(1, 0, 0, 1)) # 背景色で塗りつぶす \\
`draw(Line(v = [100, 10]), [20, 40], c=RGBA(0, 1, 0, 1))`
`pin`キーワードを設定すると描写する範囲を設定できる。
例えば、`pin = :lm`とすれば、与えた座標がlower-middleとなるような座標で描写される。
"""
function draw(dt::DataType)
    ; # do nothing
end
function draw(dt::DataType, x)
    ; # do nothing
end
# 背景の塗りつぶし
function draw(; color = RGBA(0, 0, 0, 1)) # 
    color_r = sdl_get_render_draw_color(renderer)
    sdl_set_render_draw_color(renderer, color)
    sdl_render_clear(renderer)
    sdl_set_render_draw_color(renderer, color_r)
end
# 空のオブジェクト
draw(empgeo::EmptyGeom, x, color = RGBA(1, 1, 1, 1)) = begin ; end # do nothing
# 線の描写
function draw(line::Line, x; color = RGBA(1, 1, 1, 1), linewidth = 1)
    color_r = sdl_get_render_draw_color(renderer)
    sdl_set_render_draw_color(renderer, color)
    sdl_render_draw_abstract_line(renderer, x, line.v, linewidth, 0)
    sdl_set_render_draw_color(renderer, color_r)
end
# 円、楕円、ドーナツ型の描写
function draw(circle::Circle, x; color = RGBA(1, 1, 1, 1))
    color_r = sdl_get_render_draw_color(renderer)
    sdl_set_render_draw_color(renderer, color)
    sdl_render_draw_abstract_circle(renderer, x + circle.r, circle.r0, circle.r, circle.θ)
    sdl_set_render_draw_color(renderer, color_r)
end
# 長方形の描写
function draw(rect::Rectangle, x; color = RGBA(1, 1, 1, 1), linewidth = 1, is_filled = false)
  color_r = sdl_get_render_draw_color(renderer)
  sdl_set_render_draw_color(renderer, color)
  sdl_render_draw_abstract_rect(renderer, x, rect.w, linewidth, is_filled)
  sdl_set_render_draw_color(renderer, color_r)
end
# パターン
function draw(pattern::Pattern, x; color = RGBA(1, 1, 1, 1))
    color_r = sdl_get_render_draw_color(renderer)
    sdl_set_render_draw_color(renderer, color)
    n, m = size(pattern.X)
    for i = 1:n
        points = fill(zeros(2), m)
        cnt = 1
        for j = 1:m
            if pattern.X[j, i]
                points[cnt] = intround.(x + [i, j] .- 1) 
                cnt += 1
            end
        end
        sdl_render_draw_points(renderer, points[1:cnt-2])
    end
    sdl_set_render_draw_color(renderer, color_r)
end
# Texture
function draw(moji::Texture, x)
    sdl_render_copy(
        renderer, moji.texture, 
        moji.x0, moji.w0, # コピー元
        x      , moji.w   # コピー先
    )
end
# Object
function draw(object::Object; kwargs...)
    draw(object.obj, intround.(object.topleft))
end
# Grid
function draw(gr::Grid, x; color = RGBA(1, 1, 1, 1))
    color_r = sdl_get_render_draw_color(renderer)
    sdl_set_render_draw_color(renderer, color)
    for i = 1:gr.x[1] for j = 1:gr.x[2]
        sdl_render_draw_rect(renderer, x + gr[i, j].topleft, gr.w)
    end end
    sdl_set_render_draw_color(renderer, color_r)
end
export draw






"""
scale functions
"""
function scale!(tex::Texture, a::Union{AbstractArray, Real})
    tex.w = intround.(a .* tex.w)
end
export scale!






"""
# resize functions
ImageやMojiの描画サイズを設定します。
"""
function resize!(tex::Texture, w::AbstractArray)
    tex.w = w
end
export resize!





"""
# cut_texture, cut_texture!
元画像のうち、切り取るサイズ`w`とオフセット`offset`を与え、ImageやMojiを特定の大きさで切ります。\\
特定のサイズのグリッド状にしたい場合は縦横の要素数`siz`を与えてください。

"""
function cut_texture!(tex::Texture, w; offset = [0, 0])
    if w > tex.w0 @error("NGE: cut_texture! > cut size inccorrect ?") end
    tex.x0  = tex.x0 + offset
    tex.w0  = w
    tex.w   = w
end
function cut_texture(tex::Texture)
    newtex = copy(tex)
    cut_texture!(newtex)
    return newtex
end
function cut_texture(tex::Texture, siz)
    n, m = siz
    w = tex.w0 .÷ siz
    m_tex = fill(tex, (n, m))
    for i = 1:n for j = 1:m
        newtex = copy(tex)
        cut_texture!(newtex, w, offset = ([i, j] .- 1) .* w)
        m_tex[i, j] = newtex
    end end
    return m_tex
end
export cut_texture, cut_texture!
















#=
正規表現を適当に生成したい
=#















#=

"""
# Moji
文字を扱う。
```
font = Font(file = "font.ttf")
Moji("Hello world !", font)
```
"""

mutable struct Moji <: Texture
    str::AbstractString
    x0::AbstractArray
    w0::AbstractArray
    w::AbstractArray
    a::AbstractArray
    c::AbstractRGBA
    font
    texture
    Moji(moji::Moji) = new(moji.str, moji.x0, moji.w0, moji.w, moji.a, moji.c, moji.font, moji.texture)
    function Moji(
          str, font; c = RGBA(1, 1, 1, 1)
    )
        surface = ttf_render_UTF8_blanded(font.font, str, c)
        texture = sdl_create_texture_from_surface(renderer, surface)
        sdl_free_surface(surface)
        push!(reserve_destroy, texture)
        w, h = sdl_query_texture(texture)
        return new(str, [0, 0], [w, h], [w, h], [1.0, 1.0], c, font, texture)
    end
end
export Moji
Base.copy(moji::Moji) = Moji(moji)
function Base.:*(tf::Tf, moji::Moji)
    if tf.c == Nothing
        new_moji = copy(moji)
    else 
        new_moji = Moji(moji.str, moji.font, c = tf.c)
    end
    new_moji.w = intround.(tf.a .* new_moji.w)
    return new_moji
end
Base.:*(moji::Moji, tf::Tf) = tf * moji
function draw(moji::Moji, x::AbstractArray; c = RGBA(1, 1, 1, 1))
    sdl_render_copy(
        renderer, moji.texture, 
        moji.x0, moji.w0, # コピー元
        x      , moji.w   # コピー先
    )
end
draw_at(moji::Moji, x::AbstractArray; c=RGBA(1, 1, 1, 1)) = draw(moji,  x - moji.w .÷ 2, c=c)





"""
# Image
画像を扱う
```
img = Image("image.png")
```
"""
mutable struct Image <: Texture
    file::AbstractString
    x0::AbstractArray
    w0::AbstractArray
    w::AbstractArray
    texture
    Image(img::Image) = new(img.file, img.x0, img.w0, img.w, img.texture)
    function Image(file::AbstractString)
        surface = img_load(file)
        texture = sdl_create_texture_from_surface(renderer, surface)
        sdl_free_surface(surface)
        push!(reserve_destroy, texture)
        w, h = sdl_query_texture(texture)
        return new(file, [0, 0], [w, h], [w, h], texture)
    end
end
export Image
Base.copy(img::Image) = Image(img)
function Base.:*(tf::Tf, img::Image)
    new_img = copy(img)
    new_img.w = intround.(tf.a .* img.w)
    return new_img
end
Base.:*(img::Image, tf::Tf) = tf * img
function draw(
      img::Image, x::AbstractArray
)
    sdl_render_copy(
        renderer, img.texture, 
        img.x0, img.w0, # コピー元
        x     , img.w   # コピー先
    )
end
draw_at(img::Image, x::AbstractArray) = draw(img,  x - img.w .÷ 2)







s_and_w_to_ul(s::Symbol, x::AbstractArray, w::AbstractArray) = begin
    if     s == :ul  ul = x
    elseif s == :um  ul = x - [w[1]÷2, 0     ]
    elseif s == :ur  ul = x - [w[1]  , 0     ]
    elseif s == :ml  ul = x - [ 0    , w[2]÷2]
    elseif s == :mm  ul = x - [w[1]÷2, w[2]÷2]
    elseif s == :mr  ul = x - [w[1]  , w[2]÷2]
    elseif s == :ll  ul = x - [ 0    , w[2]  ]
    elseif s == :lm  ul = x - [w[1]÷2, w[2]  ]
    elseif s == :lr  ul = x - [w[1]  , w[2]  ]
    end
    return ul
end






"""
# Boundary
禁止 \\
例えば、右上座標が[0, 0]でサイズが[50, 50]で与える四角形領域の中央座標を得るには
`bd = Boundary(w=[50, 50], ur=[0, 0]); bd.mm`とする。

以下のように、それぞれの領域が定められているものと考えてください。\\
[ul um ur; = [左上 中上 右上; \\
 ml mm mr;    左中 中中 右中; \\
 ll lm lr]    左下 中下 右下] \\

"""
struct Boundary
    w::AbstractArray  # 幅と高さ
    ul::AbstractArray # upper-left
    um::AbstractArray # upper-middle
    ur::AbstractArray # upper-right
    ml::AbstractArray # ...
    mm::AbstractArray
    mr::AbstractArray
    ll::AbstractArray
    lm::AbstractArray
    lr::AbstractArray
    top::Real
    bottom::Real
    left::Real
    right::Real
    function Boundary(w::AbstractArray; kwargs...)
        key_list = keys(kwargs)
        # upperleft, ...
        if     :ul in key_list  ul = kwargs[:ul]
        elseif :um in key_list  ul = kwargs[:um] - [w[1]÷2, 0     ] - [1, 0]
        elseif :ur in key_list  ul = kwargs[:um] - [w[1]  , 0     ] - [1, 0]
        elseif :ml in key_list  ul = kwargs[:ml] - [ 0    , w[2]÷2] - [0, 1]
        elseif :mm in key_list  ul = kwargs[:mm] - [w[1]÷2, w[2]÷2] - [1, 1]
        elseif :mr in key_list  ul = kwargs[:mr] - [w[1]  , w[2]÷2] - [1, 1]
        elseif :ll in key_list  ul = kwargs[:ll] - [ 0    , w[2]  ] - [0, 1]
        elseif :lm in key_list  ul = kwargs[:lm] - [w[1]÷2, w[2]  ] - [1, 1]
        elseif :lr in key_list  ul = kwargs[:lr] - [w[1]  , w[2]  ] - [1, 1]
        end
        um = ul + [w[1], 0] .÷ 2 - [1, 0]
        ur = ul + [w[1], 0]      - [1, 0]
        # middleleft, ...
        ml = ul + [0, w[2]] .÷ 2 - [0, 1]
        mm = ml + [w[1], 0] .÷ 2 - [1, 0]
        mr = ml + [w[1], 0]      - [1, 0]
        # lowerleft, ...
        ll = ul + [0, w[2]]      - [0, 1]
        lm = ll + [w[1], 0] .÷ 2 - [1, 0]
        lr = ll + [w[1], 0]      - [1, 0]
        left, top = ul
        right, bottom = lr
        return new(w, ul, um, ur, ml, mm, mr, ll, lm, lr, top, bottom, left, right)
    end
    #Boundary(line::Line_old; kwargs...)      = Boundary(line.vector; kwargs...)
    #Boundary(rect::Rectangle; kwargs...) = Boundary(rect.w; kwargs...)
    #Boundary(circle::Circle; kwargs...)  = Boundary(2 * circle.r; kwargs...)
    #Boundary(pat::Pattern; kwargs...)    = Boundary(collect(size(pat.X)); kwargs...)
    #Boundary(scene::Scene; kwargs...)    = Boundary(scene.w; kwargs...)
end
export Boundary
Base.:+(x::AbstractArray, bd::Boundary) = Boundary(bd.w, ul = x + bd.ul)
Base.:+(bd::Boundary, x::AbstractArray) = x + bd



=#



#=
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
end

=#



















#=
以下、バックアップ





"""
# ObjectBoundary
naiveのため、禁止
"""
struct ObjectBoundary
    x::AbstractArray
    bd::Boundary
    obj::Union{Geometry, Texture}
    # is_valid::Bool
    ObjectBoundary(objbd::ObjectBoundary) = ObjectBoundary(obj, ul = objbd.x)
    ObjectBoundary(x, bd, obj) = new(x, bd, obj)
    function ObjectBoundary(
          obj = Rectangle_old(w = [100, 100])
        ; kwargs...
    )
        bd = Boundary(obj; kwargs...)
        return new(x, bd, obj)
    end
end
Base.copy(objbd::ObjectBoundary) = ObjectBoundary(objbd)
Base.:+(x::AbstractArray, objbd::ObjectBoundary) =  ObjectBoundary(x + objbd.x, x + objbd.bd, objbd.obj)
Base.:+(objbd::ObjectBoundary, x::AbstractArray) = x + objbd
Base.:+(x::AbstractArray, obj::Union{Geometry, Texture}) = ObjectBoundary(x, Boundary(obj, ul = x), obj)
Base.:+(obj::Union{Geometry, Texture}, x::AbstractArray)  = x + obj
draw(objbd::ObjectBoundary) = draw(objbd.obj, intround.(objbd.x))






"""
# Grid_old (Iterable obj)
禁止 \\
重要な描写機能 \\
基本的には描写対象オブジェクトをまとめるグリッドを用意することに特化している。 \\
複数作成してグリッドを重ねることや、使うグリッドを変更してシーンの遷移を表現できる。\\
なお、Gridはそれ自体がオフセットを持たないので注意
## Gridの作成
[32,32]のサイズのgridを作り、gridの配置を[20,15]で構築する \\
`gr = Grid(w = [32, 32], x = [20, 15])`
## Gridの描写
gridとそれに配置されたオブジェクトを描写する \\
`draw(gr, [0, 0], c=RGBA(1, 0, 0, 1))`
"""
mutable struct Grid_old
    w::AbstractArray
    x::AbstractArray
    ofs::AbstractArray
    bd::Matrix{Boundary}
    attr::Matrix{Any}
    Grid_old(gr::Grid_old) = new(gr.w, gr.x, gr.ofs, gr.bd)
    Grid_old(w, x, ofs, bd) = new(w, x, ofs, bd)
    function Grid_old(
        ; w  = [ 32,  32]
        , x  = [ 20,  15]
        , ofs= [  0,   0] # オフセット座標
    )
        bd = fill(Boundary(w, ul=[0, 0]), Tuple(x)) 
        for i = 1:x[1] for j = 1:x[2]
            ul = ofs + ([i, j] .- 1) .* w
            bd[i, j] = Boundary(w, ul=ul)
        end end
        return new(w, x, ofs, bd)
    end
end
export Grid_old
function draw(
      gr::Grid_old, x::AbstractArray
    ; c = RGBA(1, 1, 1, 1)
)
    color_r = sdl_get_render_draw_color(renderer)
    sdl_set_render_draw_color(renderer, c)
    for i = 1:gr.x[1] for j = 1:gr.x[2]
        sdl_render_draw_rect(renderer, x + gr[i, j].ul, gr.w)
    end end
    sdl_set_render_draw_color(renderer, color_r)
end
export draw
# Base.getindex(gr::Grid, i::Union{Int, AbstractVector{Int64}}, j::Union{Int, AbstractVector{Int64}}) = gr.bd[i, j] # Type Boundary
Base.getindex(gr::Grid_old, i::Int, j::Int) = gr.bd[i, j]
function Base.getindex(gr::Grid_old, ii::AbstractVector{Int64}, jj::AbstractVector{Int64})
    w   = gr.w
    x   = length.([ii, jj])
    ofs = gr.ofs + w .* ([ii[1], jj[1]] .- 1)
    bd  = gr.bd[ii, jj]
    return Grid_old(w, x, ofs, bd)
end
function Base.collect(gr::Grid_old)
    A = fill(gr[1, 1], Tuple(gr.x))
    for i = 1:gr.x[1] for j = 1:gr.x[2]
        A[i, j] = gr[i, j]
    end end
    return A
end
Base.size(gr::Grid_old, d::Integer) = gr.x[d]
Base.size(gr::Grid_old) = (size(gr, 1), size(gr, 2))






function each_intersects(obj::Boundary, v::AbstractArray)
    left, upper = obj.ul .< v
    right,lower = v .< obj.lr
    return [left & upper  right & upper; 
            left & lower  right & lower]
end
function map_intersects(obj::Boundary, bd::Boundary)
    ret = ones(Bool, 3, 3)
    ret[1:2, 1:2] .&= each_intersects(obj, bd.ul)
    ret[1:2, 2:3] .&= each_intersects(obj, bd.ur)
    ret[2:3, 1:2] .&= each_intersects(obj, bd.ll)
    ret[2:3, 2:3] .&= each_intersects(obj, bd.lr)
    return ret
end
"""
# Intersects
禁止
"""
struct Intersects_old
    top::Bool     # 上がbdに触れている
    bottom::Bool  # 下が...
    left::Bool    # 左が...
    right::Bool   # 右が...
    bounded::Bool # bd内部に含まれている
    bounds::Bool  # obj内部にbdを含む
    outside_upper::Bool
    outside_lower::Bool
    outside_left::Bool
    outside_right::Bool
    outside::Bool
    inside::Bool
    Intersects_old(obj::Boundary, bd::Boundary) = begin
        t = map_intersects(obj, bd)
        sum_t   = sum(t)
        top     = all(t[1:2, 2])
        bottom  = all(t[2:3, 2])
        left    = all(t[2, 1:2])
        right   = all(t[2, 2:3])
        bounded = t[2,2] & (sum_t == 1)
        bounds  = all(t)
        outside_upper  = any(t[1, 1:3]) & (! top)
        outside_lower  = any(t[3, 1:3]) & (! bottom)
        outside_left   = any(t[1:3, 1]) & (! left)
        outside_right  = any(t[1:3, 3]) & (! right)
        outside = outside_upper | outside_lower | outside_left | outside_right
        inside  = bounded
        return new(top, bottom, left, right, bounded, bounds, outside_upper, outside_lower, outside_left, outside_right, outside, inside)
    end
end
export Intersects_old
Intersects_old(objbd::ObjectBoundary, Objbd::ObjectBoundary) = Intersects_old(objbd.bd, Objbd.bd)
Intersects_old(objbd::ObjectBoundary, bd::Boundary) = Intersects_old(objbd.bd, bd)
Intersects_old(bd::Boundary, Objbd::ObjectBoundary) = Intersects_old(bd, Objbd.bd)
Base.any(its::Intersects_old) = its.top | its.bottom | its.left | its.right | its.bounded | its.bounds







"""
# Line
## howtouse \\
line = Line(v = [100, 50]) \\
line2 = Tf(a=[1, 1.5]) * line \\
"""
mutable struct Line_old <: Geometry
    vector::AbstractArray{Int}
    w::AbstractArray
    Line_old(line::Line_old) = Line_old(vector = line.vector)
    function Line_old(
        ; vector = [100, 100]
    )
        w = vector
        return new(vector, w)
    end
end
export Line_old
Base.copy(line::Line_old) = Line_old(line)
function Base.:*(tf::Tf, line::Line_old)
    newline = copy(line)
    if tf.θ != 0
        newline.vector = intround.(rot_2d_matrix(tf.θ) * line.vector)
    end
    if tf.a != [0, 0]
        newline.vector = intround.(tf.a .* line.vector)
    end
    return newline
end
function Base.:*(line::Line_old, tf::Tf) return tf * line
end
function draw(
      line::Line_old, x::AbstractArray
    ; c          = RGBA(1, 1, 1, 1)
    , linewidth  = 1
    , pin        = :ul
)
    color_r = sdl_get_render_draw_color(renderer)
    sdl_set_render_draw_color(renderer, c)
    if pin != :ul  x = s_and_w_to_ul(pin, x, line.vector)  end
    sdl_render_draw_abstract_line(renderer, x, line.vector, linewidth, 0)
    sdl_set_render_draw_color(renderer, color_r)
end
function draw_at(line::Line_old, x; kargs...)
    draw(line, x - line.vector .÷ 2, kargs...)
end
export draw, draw_at









"""
# Circle
円、楕円、ドーナツ型オブジェクト \\
circle = Circle() #半径100の縁を生成 \\
"""
mutable struct Circle_old <: Geometry
    r0::AbstractArray
    r::AbstractArray
    θ::Real
    w::AbstractArray
    Circle_old(circle::Circle_old) = Circle_old(r0=circle.r0, r=circle.r, θ=circle.θ)
    function Circle_old(
        ; r  = 100
        , r0 = r
        , θ  = 0 
    )
        if typeof(r)  <: Real  r  = [r, r]
        end
        if typeof(r0) <: Real  r0 = [r0, r0]
        end
        w = 2 * r
        return new(r0, r, θ, w)
    end
end
export Circle_old
Base.copy(circle::Circle_old) = Circle_old(circle)
function Base.:*(tf::Tf, circle::Circle_old)
    newcircle = copy(circle)
    if tf.θ != 0
        newicrcle.θ = tf.θ + circle.θ
    end
    if tf.a != [0, 0]
        newcircle.r  = intround.(tf.a .* circle.r) 
        newcircle.r0 = intround.(tf.a .* circle.r0) 
    end
    return newcircle
end
Base.:*(circle::Circle_old, tf::Tf) = tf * circle
function draw(
      circle::Circle_old, x::AbstractArray
    ; c   = RGBA(1, 1, 1, 1)
    , pin = :ul
)
    color_r = sdl_get_render_draw_color(renderer)
    sdl_set_render_draw_color(renderer, c)
    if pin != :ul  x = s_and_w_to_ul(pin, x, 2*circle.r)  end
    sdl_render_draw_abstract_circle(renderer, x + circle.r, circle.r0, circle.r, circle.θ)
    sdl_set_render_draw_color(renderer, color_r)
end
function draw_at(circle::Circle_old, x; kargs...)
    draw(circle, x - circle.r; kargs...)
end





"""
# Rectangle
"""
mutable struct Rectangle_old <: Geometry
    w::AbstractArray
    lw::Real
    c::AbstractRGBA
    is_filled::Bool
    Rectangle_old(rect::Rectangle_old) = Rectangle_old(w=rect.w, lw=rect.width, c=rect.c, is_filled=rect.is_filled)
    function Rectangle_old(
        ; w  = [100, 100]
        , lw = 1
        , c  = RGBA(1, 1, 1, 1)
        , is_filled = false
    )
        return new(w, lw, c, is_filled)
    end
end
export Rectangle_old
Base.copy(rect::Rectangle_old) = Rectangle_old(rect)
function Base.:*(tf::Tf, rect::Rectangle_old)
    new_rect = copy(rect)
    new_rect.w = tf.a .* rect.w
    return new_rect
end
Base.:*(rect::Rectangle_old, tf::Tf) = tf * rect
function draw(
      rect::Rectangle_old, x::AbstractArray
    ; c         = RGBA(1, 1, 1, 1)
    , linewidth = 1
    , pin       = :ul
)
    if pin == :topleft pin = :ul end
    color_r = sdl_get_render_draw_color(renderer)
    sdl_set_render_draw_color(renderer, c)
    if pin != :ul  x = s_and_w_to_ul(pin, x, rect.w) end
    sdl_render_draw_abstract_rect(renderer, x, rect.w, linewidth, rect.is_filled)
    sdl_set_render_draw_color(renderer, color_r)
end
draw_at(rect::Rectangle_old, x::AbstractArray; c = RGBA(1, 1, 1, 1)) = draw(rect, x + intround.(rect.w / 2), c=c)





"""
Pattern
以下のようにすると30*30の凹のような図形になります。\\
`pat = 10 * Pattern([
    true false true;
    true false true;
    true true  true
])`
"""
mutable struct Pattern_old <: Geometry
    X::Matrix{Bool}
    w::AbstractArray
    Pattern_old(pat::Pattern_old) = Pattern_old(X=pat.X)
    function Pattern_old(
        ; X = [true]
    )
        w = collect(size(X))
        return new(X, w)
    end
end
export Pattern_old
Base.copy(pat::Pattern_old) = Pattern_old(pat)
function Base.:*(tf::Tf, pat::Pattern_old) 
    new_pat = copy(pat)
    ext = ones(Bool, tf.a[1], tf.a[2])
    new_pat.X = kron(new_pat.X, ext)
    return new_pat
end
Base.:*(pat::Pattern_old, tf::Tf) = tf * pat
function draw(pattern::Pattern_old, x::AbstractArray; c = RGBA(1, 1, 1, 1))
    global renderer
    color_r = sdl_get_render_draw_color(renderer)
    sdl_set_render_draw_color(renderer, c)
    n, m = size(pattern.X)
    for i = 1:n
        points = fill(zeros(2), m)
        cnt = 1
        for j = 1:m
            if pattern.X[j, i]
                points[cnt] = intround.(x + [i, j] .- 1) 
                # sdl_render_draw_point(renderer, x + [i, j] .- 1)
                cnt += 1
            end
        end
        sdl_render_draw_points(renderer, points[1:cnt-2])
    end
    sdl_set_render_draw_color(renderer, color_r)
end
draw_at(pattern::Pattern_old, x::AbstractArray; c = RGBA(1, 1, 1, 1)) = draw(pattern, x - collect(size(pattern.X)) .÷ 2, c=c)

=#



#=
"""
# resize_texture!
ImageやMojiの描画サイズを設定します。
```
# img::Imageを[32, 32]の描写サイズに設定
resize_texture!(img, [32, 32])
```
"""
function resize_texture!(tex::Texture, w::AbstractArray)
    tex.w = w
end
export resize_texture!





"""
# cut_texture
ImageやMojiを特定の大きさで切ります。
```
# 画像から画像の右上から32*32のカット画像を作成
bd = Boundary(w=[32, 32], ul=[0, 0])
img2 = cut_texture(img, bd)
# (12,3)のサイズで画像を切って画像の配列を生成
gr   = Grid(w=img.w .÷ [12, 3], x=[12, 3])
imgs = (x -> cut_texture(imgs, x)).(gr)
```
"""
function cut_texture(tex::Texture, bd::Boundary)
    new_tex = copy(tex)
    new_tex.file = ""
    new_tex.x0   = bd.ul
    new_tex.w0   = bd.w
    new_tex.w    = bd.w
    return new_tex
end
cut_texture(tex::Texture, gr::Grid_old) = (x -> cut_texture(tex, x)).(gr)
function cut_texture(tex::Texture, x::AbstractArray, require_grid = false) 
    gr = Grid_old(w=tex.w0 .÷ x, x = x)
    newtex = cut_texture(tex, gr)
    if require_grid return newtex, gr
    else            return newtex
    end
end
export cut_texture

=#




end # module NGE
