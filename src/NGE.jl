module NGE

include("./NGESDL.jl")

using .NGESDL
using Colors, LinearAlgebra

global section, win, renderer, event_ref, events, t0, t_old

global reserve_close
reserve_close = [] # close all

global reserve_destroy
reserve_destroy = [] # destroy all

include("./NGEApp.jl")


intround      = (x -> Int(round(x)))
intfloor      = (x -> Int(floor(x)))
intceil       = (x -> Int(ceil(x)))
uint8round    = (x -> UInt8(round(x)))
uint8round255 = (x -> UInt8(round(x*255)))
rot_2d_matrix(θ::Real) = [cos(θ) -sin(θ); sin(θ) cos(θ)]
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
    # Boundary(rect::Rectangle; lwargs...) = Boundary(rect.w, lwargs...)
    function Boundary(w::AbstractArray; lwargs...)
        key_list = keys(lwargs)
        # upperleft, ...
        if     :ul in key_list  ul = lwargs[:ul]
        elseif :um in key_list  ul = lwargs[:um] - [w[1]÷2, 0     ]
        elseif :ur in key_list  ul = lwargs[:um] - [w[1]  , 0     ]
        elseif :ml in key_list  ul = lwargs[:ml] - [ 0    , w[2]÷2]
        elseif :mm in key_list  ul = lwargs[:mm] - [w[1]÷2, w[2]÷2]
        elseif :mr in key_list  ul = lwargs[:mr] - [w[1]  , w[2]÷2]
        elseif :ll in key_list  ul = lwargs[:ll] - [ 0    , w[2]  ]
        elseif :lm in key_list  ul = lwargs[:lm] - [w[1]÷2, w[2]  ]
        elseif :lr in key_list  ul = lwargs[:lr] - [w[1]  , w[2]  ]
        end
        um = ul + [w[1], 0] .÷ 2
        ur = ul + [w[1], 0]
        # middleleft, ...
        ml = ul + [0, w[2]] .÷ 2
        mm = ml + [w[1], 0] .÷ 2
        mr = ml + [w[1], 0]
        # lowerleft, ...
        ll = ul + [0, w[2]]
        lm = ll + [w[1], 0] .÷ 2
        lr = ll + [w[1], 0] 
        return new(w, ul, um, ur, ml, mm, mr, ll, lm, lr)
    end
end
export Boundary




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
"""
struct Intersects
    top::Bool     # 上がbdに触れている
    buttom::Bool  # 下が...
    left::Bool    # 左が...
    right::Bool   # 右が...
    bounded::Bool # bd内部に含まれている
    bounds::Bool  # obj内部にbdを含む
    Intersects(obj::Boundary, bd::Boundary) = begin
        t = map_intersects(obj, bd)
        top     = all(t[1:2, 2])
        buttom  = all(t[2:3, 2])
        left    = all(t[2, 1:2])
        right   = all(t[2, 2:3])
        bounded = (t[2,2] == true) & (sum(t) == 1)
        bounds  = all(t)
        return new(top, buttom, left, right, bounded, bounds)
    end
end
export Intersects
Base.any(its::Intersects) = its.top | its.buttom | its.left | its.right | its.bounded | its.bounds





"""
# draw関数 
以下のように用いる。\\
`draw(Object::TYPE <: Union{Geometry, Image, Moji}, vpos, c=color)`
## how to use 
draw(c = RGBA(1, 0, 0, 1)) # 背景色で塗りつぶす \\
`draw(Line(v = [100, 10]), [20, 40], c=RGBA(0, 1, 0, 1))`
`pin`キーワードを設定すると描写する範囲を設定できる。
例えば、`pin = :lm`とすれば、与えた座標がlower-middleとなるような座標で描写される。
"""
function draw(;c = RGBA(0, 0, 0, 1))
    color_r = sdl_get_render_draw_color(renderer)
    sdl_set_render_draw_color(renderer, c)
    sdl_render_clear(renderer)
    sdl_set_render_draw_color(renderer, color_r)
end





"""
# Grid (Iterable obj)
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
mutable struct Grid
    w::AbstractArray
    x::AbstractArray
    ofs::AbstractArray
    bd::Matrix{Boundary} # pos::AbstractArray
    Grid(gr::Grid) = new(gr.w, gr.x, gr.ofs, gr.bd)
    Grid(w, x, ofs, bd) = new(w, x, ofs, bd)
    function Grid(
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
export Grid
function draw(
      gr::Grid, x::AbstractArray
    ; c = RGBA(1, 1, 1, 1)
)
    color_r = sdl_get_render_draw_color(renderer)
    sdl_set_render_draw_color(renderer, c)
    for i = 1:gr.x[1] for j = 1:gr.x[2]
        # sdl_render_draw_rect(renderer, x + gr.pos[i, j], gr.w)
        sdl_render_draw_rect(renderer, x + gr[i, j].ul, gr.w)
    end end
    sdl_set_render_draw_color(renderer, color_r)
end
export draw
# Base.getindex(gr::Grid, i::Union{Int, AbstractVector{Int64}}, j::Union{Int, AbstractVector{Int64}}) = gr.bd[i, j] # Type Boundary
Base.getindex(gr::Grid, i::Int, j::Int) = gr.bd[i, j]
function Base.getindex(gr::Grid, ii::AbstractVector{Int64}, jj::AbstractVector{Int64})
    w   = gr.w
    x   = length.([ii, jj])
    ofs = gr.ofs + w .* ([ii[1], jj[1]] .- 1)
    bd  = gr.bd[ii, jj]
    return Grid(w, x, ofs, bd)
end
function Base.collect(gr::Grid)
    A = fill(gr[1, 1], Tuple(gr.x))
    for i = 1:gr.x[1] for j = 1:gr.x[2]
        A[i, j] = gr[i, j]
    end end
    return A
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
AbstractType Geometry
"""
abstract type Geometry end





"""
# Line
## howtouse \\
line = Line(v = [100, 50]) \\
line2 = Tf(a=[1, 1.5]) * line \\
"""
mutable struct Line <: Geometry
    vector::AbstractArray{Int}
    Line(line::Line) = Line(vector = line.vector)
    function Line(
        ; vector = [100, 100]
    )
        return new(vector)
    end
end
export Line
Base.copy(line::Line) = Line(line)
function Base.:*(tf::Tf, line::Line)
    newline = copy(line)
    if tf.θ != 0
        newline.vector = intround.(rot_2d_matrix(tf.θ) * line.vector)
    end
    if tf.a != [0, 0]
        newline.vector = intround.(tf.a .* line.vector)
    end
    return newline
end
function Base.:*(line::Line, tf::Tf) return tf * line
end
function draw(
      line::Line, x::AbstractArray
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
function draw_at(line::Line, x; kargs...)
    draw(line, x - line.vector .÷ 2, kargs...)
end
export draw, draw_at





"""
# Circle \\
円、楕円、ドーナツ型オブジェクト \\
circle = Circle() #半径100の縁を生成 \\
"""
mutable struct Circle <: Geometry
    r0::AbstractArray
    r::AbstractArray
    θ::Real
    Circle(circle::Circle) = Circle(r0=circle.r0, r=circle.r, θ=circle.θ)
    function Circle(
        ; r  = 100
        , r0 = r
        , θ  = 0 
    )
        if typeof(r)  <: Real  r  = [r, r]
        end
        if typeof(r0) <: Real  r0 = [r0, r0]
        end
        return new(r0, r, θ)
    end
end
export Circle
Base.copy(circle::Circle) = Circle(circle)
function Base.:*(tf::Tf, circle::Circle)
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
Base.:*(circle::Circle, tf::Tf) = tf * circle
function draw(
      circle::Circle, x::AbstractArray
    ; c   = RGBA(1, 1, 1, 1)
    , pin = :ul
)
    color_r = sdl_get_render_draw_color(renderer)
    sdl_set_render_draw_color(renderer, c)
    if pin != :ul  x = s_and_w_to_ul(pin, x, 2*circle.r)  end
    sdl_render_draw_abstract_circle(renderer, x + circle.r, circle.r0, circle.r, circle.θ)
    sdl_set_render_draw_color(renderer, color_r)
end
function draw_at(circle::Circle, x; kargs...)
    draw(circle, x - circle.r, kargs...)
end





"""
# Rectangle
"""
mutable struct Rectangle <: Geometry
    w::AbstractArray
    lw::Real
    c::AbstractRGBA
    is_filled::Bool
    Rectangle(rect::Rectangle) = Rectangle(w=rect.w, lw=rect.width, c=rect.c, is_filled=rect.is_filled)
    function Rectangle(
        ; w  = [100, 100]
        , lw = 1
        , c  = RGBA(1, 1, 1, 1)
        , is_filled = false
    )
        return new(w, lw, c, is_filled)
    end
end
export Rectangle
Base.copy(rect::Rectangle) = Rectangle(rect)
function Base.:*(tf::Tf, rect::Rectangle)
    new_rect = copy(rect)
    new_rect.w = tf.a .* rect.w
    return new_rect
end
Base.:*(rect::Rectangle, tf::Tf) = tf * rect
function draw(
      rect::Rectangle, x::AbstractArray
    ; c         = RGBA(1, 1, 1, 1)
    , linewidth = 1
    , pin       = :ul
)
    color_r = sdl_get_render_draw_color(renderer)
    sdl_set_render_draw_color(renderer, c)
    if pin != :ul  x = s_and_w_to_ul(pin, x, rect.w) end
    sdl_render_draw_abstract_rect(renderer, x, rect.w, linewidth, rect.is_filled)
    sdl_set_render_draw_color(renderer, color_r)
end
draw_at(rect::Rectangle, x::AbstractArray; c = RGBA(1, 1, 1, 1)) = draw(rect, x + intround.(rect.w / 2), c=c)





"""
Pattern
以下のようにすると30*30の凹のような図形になります。\\
`pat = 10 * Pattern([
    true false true;
    true false true;
    true true  true
])`
"""
mutable struct Pattern <: Geometry
    X::Matrix{Bool}
    Pattern(pat::Pattern) = Pattern(X=pat.X)
    function Pattern(
        ; X = [true]
    )
        return new(X)
    end
end
export Pattern
Base.copy(pat::Pattern) = Pattern(pat)
function Base.:*(tf::Tf, pat::Pattern) 
    new_pat = copy(pat)
    ext = ones(Bool, tf.a[1], tf.a[2])
    new_pat.X = kron(new_pat.X, ext)
    return new_pat
end
Base.:*(pat::Pattern, tf::Tf) = tf * pat
function draw(pattern::Pattern, x::AbstractArray; c = RGBA(1, 1, 1, 1))
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
draw_at(pattern::Pattern, x::AbstractArray; c = RGBA(1, 1, 1, 1)) = draw(pattern, x - collect(size(pattern.X)) .÷ 2, c=c)





"""
# Font
```
font = Font(file="...")
```
"""
struct Font
    file::AbstractString
    font
    Font(font::Font) = Font(file=font.file) # あんまり意味ない
    function Font(file)
        font = ttf_open_font(file) 
        push!(reserve_close, font)
        if Int(font) == 0  error("NGE: ttf error can't read a font file") 
        end
        return new(file, font)
    end
end
export Font



abstract type Texture end



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
cut_texture(tex::Texture, gr::Grid) = (x -> cut_texture(tex, x)).(gr)
function cut_texture(tex::Texture, x::AbstractArray, require_grid = false) 
    gr = Grid(w=tex.w0 .÷ x, x = x)
    newtex = cut_texture(tex, gr)
    if require_grid return newtex, gr
    else            return newtex
    end
end
export cut_texture






end # module NGE
