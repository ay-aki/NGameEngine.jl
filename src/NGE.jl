module NGE

include("./NGESDL.jl")

using .NGESDL
using Colors, LinearAlgebra

global section, win, renderer, event_ref, events, t0, t_old

#= 
設計指向
> Siv3dを参考にしたい。
> juliaの文法を生かせるようにしたい。
> gr = grid([20, 15])みたいにして、gr.pos[4, 5] を指定して描写する
> draw(, gr.pos[4, 5])
> 0.1 * rectとかすることでスケールできるようにしたい。
> [0.1. 0.5] * rectで横縦をスケールできるようにしたい。
> π ^ rect で回転させたい
> 

命名規則
> v, w, x, y, zは位置や直線などのベクトルを表す
> c はカラーを表す
> linewidth は線の幅を表す
> tはゲーム内時間を表す
> dtはゲーム内時間の変位を表す
> centerは重心を表す
> downはボタンが押されることを表す
> upはボタンを離すことを表す
=#

#=
ゲームオブジェクト
=#
mutable struct Info
    title::AbstractString
    Info() = new("Title")
end
export Info

mutable struct Scene
    w::AbstractArray # ウインドウサイズ
    center::AbstractArray
    t
    dt
    Scene(w, t, dt)  = new(w, w / 2.0, t, dt)
    Scene() = Scene([640, 480], 0.0, 0.0)
end
export Scene

mutable struct Button
    down::Bool
    up::Bool
    Button(down, up) = new(down, up)
    Button() = new(false, false)
end

mutable struct Mouse
    x::AbstractArray
    lbutton::Button
    rbutton::Button
    Mouse(x, lbutton, rbutton) = new(x, lbutton, rbutton)
    Mouse() = Mouse([-1, -1], Button(), Button())
end
export Mouse

mutable struct Keyboard
    keys  # 取得したいキーのリスト
    scans # キーに対応するフラグのリスト
    Keyboard() = new([], Dict())
end
export Keyboard

mutable struct System
    win
    renderer
    mouse::Mouse
    keyboard::Keyboard
    System() = new(Nothing, Nothing, Mouse(), Keyboard())
end
export System

f_blank = () -> ()
mutable struct App
    info::Info
    scene::Scene
    system::System
    main::Function
    App() = new(Info(), Scene(), System(), f_blank)
end
export App


intround = (x -> Int(round(x)))
intfloor = (x -> Int(floor(x)))
intceil  = (x -> Int(ceil(x)))
rot_2d_matrix(θ::Real) = [cos(θ) -sin(θ); sin(θ) cos(θ)]

# pkgdir


"""
# draw関数 \\
draw(Object::TYPE <: Geometry, vpos, c=color)のように使う。\\
## how to use \\
draw(c = RGBA(1, 0, 0, 1)) # 背景色で塗りつぶす \\
draw(Line(v = [100, 10]), [20, 40], c=RGBA(0, 1, 0, 1)) \\
"""
function draw(;c = RGBA(0, 0, 0, 1))
    color_r = sdl_get_render_draw_color(renderer)
    sdl_set_render_draw_color(renderer, c)
    sdl_render_clear(renderer)
    sdl_set_render_draw_color(renderer, color_r)
end



#=  
# Grid
32*32のサイズのgridを作り、gridの配置を20*15で構築する \\
gr = Grid(w = [32, 32], x = [20, 15]) \\
例えば、配置したい座標は以下のようにイテレーションできる
=#
mutable struct Grid
    w::AbstractArray  # gridwidth
    x::AbstractArray  # [i, j] grids
    wx::AbstractArray # w.*x
    pos::AbstractArray# upperleft position of grid
    Grid(grid::Grid) = Grid(w = grid.w, x = grid.x, wx = grid.wx)
    function Grid(
        ; w  = [ 32,  32]
        , x  = [ 20,  15]
        , wx = [640, 480]
    )
        if w .* x != wx
            if     w  != [ 32,  32] w  = intround(wx ./ x)
            elseif x  != [ 20,  15] x  = intround(wx ./ w)
            elseif wx != [640, 480] wx = intround(w  .* x)
            end
        end
        pos = fill(Int.(zeros(2)), Tuple(x))
        for i = 1:x[1]
            for j = 1:x[2]
                pos[i, j] = ([i, j] .- 1) .* w
            end
        end
        return new(w, x, wx, pos)
    end
end
export Grid



#=
Tf
移動や回転、色の変更を与える。
=#
mutable struct Tf
    a::AbstractArray
    θ::Real
    Tf(tf::Tf) = Tf(a=tf.a, θ=tf.θ)
    function Tf(
        ; a = 1.0 # scaling param
        , θ = 0.0 # [radian]
    )
        if typeof(a) <: Real  a = [a, a]
        end
        return new(a, θ)
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




#=
Geometry(Abstract type)
=#
abstract type Geometry end



"""
# Lineオブジェクト \\
## howtouse \\
line = Line(v = [100, 50]) \\
line2 = Tf(a=[1, 1.5]) * line \\
"""
mutable struct Line <: Geometry
    v::AbstractArray
    lw::Int
    θ::Real
    Line(line::Line) = Line(v=line.v, lw=line.lw, θ=line.θ)
    function Line(
        ; v  = [100, 100]
        , lw = 1
        , θ  = 0.0 # [radian]
    )
        return new(v, lw, θ)
    end
end
export Line
Base.copy(line::Line) = Line(line)
function Base.:*(tf::Tf, line::Line)
    newline = copy(line)
    newline.v = intround.(tf.a .* newline.v)
    newline.θ = tf.θ + newline.θ
    return newline
end
Base.:*(line::Line, tf::Tf) = tf * line
function draw(line::Line, x::AbstractArray; c = RGBA(1, 1, 1, 1))
    global renderer
    color_r = sdl_get_render_draw_color(renderer)
    sdl_set_render_draw_color(renderer, c)
    sdl_render_draw_abstract_line(renderer, x, line.v, line.lw, line.θ)
    sdl_set_render_draw_color(renderer, color_r)
end
draw_at(line::Line, x::AbstractArray; c = RGBA(1, 1, 1, 1)) = draw(line, x - line.v / 2, c=c)
export draw, draw_at



#=
Circle
円、楕円、ドーナツオブジェクト
circle = Circle(r=)
=#
mutable struct Circle <: Geometry
    r::AbstractArray
    r0::AbstractArray
    θ::Real
    Circle(circle::Circle) = Circle(r=circle.r, r0=circle.r0, θ=circle.θ)
    function Circle(
        ; r  = [100, 100]
        , r0 = r
        , θ  = 0 
    )
        return new(r, r0, θ)
    end
end
export Circle
Base.copy(circle::Circle) = Circle(circle)
function Base.:*(tf::Tf, circle::Circle)
    newcircle = copy(circle)
    newcircle.r = intround.(tf.a .* newcircle.r)
    newcircle.r0= intround.(tf.a .* newcircle.r0)
    newcircle.θ = tf.θ + newcircle.θ
    return newcircle
end
Base.:*(circle::Circle, tf::Tf) = tf * circle
function draw(circle::Circle, x::AbstractArray; c = RGBA(1, 1, 1, 1))
    global renderer
    color_r = sdl_get_render_draw_color(renderer)
    sdl_set_render_draw_color(renderer, c)
    sdl_render_draw_abstract_circle(renderer, x + circle.r, circle.r0, circle.r, circle.θ)
    sdl_set_render_draw_color(renderer, color_r)
end
draw_at(circle::Circle, x::AbstractArray; c = RGBA(1, 1, 1, 1)) = draw(circle, x - circle.r, c=c)



#=
Rectangle
=#
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
    new_rect.w = tf.a .* new_rect
    return new_rect
end
Base.:*(rect::Rectangle, tf::Tf) = tf * rect
function draw(rect::Rectangle, x::AbstractArray; c = RGBA(1, 1, 1, 1))
    global renderer
    color_r = sdl_get_render_draw_color(renderer)
    sdl_set_render_draw_color(renderer, c)
    sdl_render_draw_abstract_rect(renderer, x, rect.w, rect.lw, rect.is_filled)
    sdl_set_render_draw_color(renderer, color_r)
end
draw_at(rect::Rectangle, x::AbstractArray; c = RGBA(1, 1, 1, 1)) = draw(rect, x + intround.(rect.w / 2), c=c)



#=
Pattern
以下のようにすると凹のような図形になります。
pat = 10 * Pattern([
    true false true;
    true false true;
    true true  true
])
=#
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






#=
ゲーム設定
=#
"""
キーボードキー登録
"""
function register_keys!(g::App, ss)
    for s in ss
        push!(g.system.keyboard.keys, s)
        g.system.keyboard.scans[s] = Button(false, false)
    end
end
export register_keys!


"""
ゲーム初期化関数
"""
function beginapp(g::App)
    global section, win, renderer, event_ref, t0, t_old
    sdl_init()
    win, renderer = sdl_create_window_and_renderer(g.info.title, g.scene.w)
    event_ref = sdl_event_init()
    sdl_render_clear(renderer)
    sdl_render_present(renderer)
    #=this is main/=#
    # section = [0, 0]
    t0 = t_old = time()
end
export beginapp


"""
ゲーム終了関数
"""
function endapp(g::App)
    global section, win, renderer, event_ref, t0, t_old
    # section = [1, 0]
    #=/this is main=#
    sdl_destroy_window_and_renderer(win, renderer)
    sdl_quit()
end
export endapp


"""
ゲーム実行関数
"""
function runapp(g::App)
    global section, win, renderer, event_ref, t0, t_old
    beginapp(g)
    g.main()
    endapp(g)
end
export runapp


"""
ゲーム更新関数
"""
function update!(g::App)
    global event_ref, events, t0, t_old
    sdl_render_present(renderer) # 画面更新
    sdl_render_clear(renderer)   # レンダークリア
    t = time()
    g.scene.dt = t - t_old
    t_old = time()
    g.scene.t = t - t0
    for s = g.system.keyboard.keys
        g.system.keyboard.scans[s].down = false
        g.system.keyboard.scans[s].up = false
    end
    g.system.mouse.lbutton.down = false
    g.system.mouse.rbutton.down = false
    events = sdl_poll_events(event_ref)
    for e in events
        if     sdl_event_is(e, :SDL_QUIT)
            return false
        elseif sdl_event_is(e, :SDL_KEYDOWN)
            for s = g.system.keyboard.keys
                if sdl_scancode_is(e, s)
                    g.system.keyboard.scans[s].down = true
                end
            end
        elseif sdl_event_is(e, :SDL_KEYUP)
            for s = g.system.keyboard.keys
                if sdl_scancode_is(e, s)
                    g.system.keyboard.scans[s].up = true
                end
            end
        elseif sdl_event_is(e, :SDL_MOUSEBUTTONDOWN)
            if     sdl_mousebutton_is(e, :SDL_BUTTON_LEFT )
                g.system.mouse.lbutton.down = true
            elseif sdl_mousebutton_is(e, :SDL_BUTTON_RIGHT)
                g.system.mouse.rbutton.down = true
            end
        elseif sdl_event_is(e, :SDL_MOUSEBUTTONUP)
            if     sdl_mousebutton_is(e, :SDL_BUTTON_LEFT )
                g.system.mouse.lbutton.up = true
            elseif sdl_mousebutton_is(e, :SDL_BUTTON_RIGHT)
                g.system.mouse.rbutton.up = true
            end
        end
    end
    g.system.mouse.x = sdl_mouse_position()
    
    #=
    if true in sdl_event_is_quit.(events)
        return false
    end=#
    return true
end
export update!


"""
REPL用安定更新マクロ
"""
macro update!(g)
    quote
        for i = 1:5
            update!($(esc(g)))
        end
    end
end
macro update!(g, expr)
    quote
        for i = 1:5
            update!($(esc(g)))
        end
        $(esc(expr))
        update!($(esc(g)))
    end
end
export @update!



end # module NGE
