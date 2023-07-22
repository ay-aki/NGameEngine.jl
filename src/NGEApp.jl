

#=
・習熟に時間が掛からない
・コードの可読性が高い
・自然な文法
=#

using .NGESDL
using Colors, LinearAlgebra

global section, win, renderer, event_ref, events, t0, t_old

global reserve_close
reserve_close = [] # close all

global reserve_destroy
reserve_destroy = [] # destroy all

# wins, renderers



mutable struct Info
    title::AbstractString
end
Info() = Info("Title")

mutable struct Timing
    keys
    timers
    timings # Bool
end
Timing() = Timing([], Dict(), Dict())
function Base.getindex(ti::Timing, dt::Real)
    if !(dt in ti.keys)
        push!(ti.keys, dt)
        ti.timers[dt]  = 0.0
        ti.timings[dt] = false
    end
    return ti.timings[dt]
end

mutable struct Scene
    w::AbstractArray # ウインドウサイズ
    center::AbstractArray
    t
    dt
    timing::Timing
end
export Scene
Scene(w) = Scene(w, w .÷ 2, 0.0, 0.0, Timing())
Scene()  = Scene([640, 480])

mutable struct Wheel
    dx::AbstractArray
    is_wheeled::Bool
end
Wheel() = Wheel([0, 0], false)

mutable struct Button
    down::Bool
    up::Bool
end
Button() = Button(false, false)

mutable struct Mouse
    x::AbstractArray
    lbutton::Button
    rbutton::Button
    wheel::Wheel
end
Mouse() = Mouse([-1, -1], Button(), Button(), Wheel())

mutable struct Keyboard
    keys  # 取得したいキーのリスト
    scans # キーに対応するフラグのリスト
end
Keyboard() = Keyboard([], Dict())

mutable struct InputText
    text::AbstractString
    textlength::Integer
    composition::AbstractString
    cursor::Integer
    select_len::Integer
end
InputText() = InputText("", 100, "", 0, 0)

mutable struct System
    win # 未使用 
    renderer # 未使用
    mouse::Mouse
    keyboard::Keyboard
    inputtext::InputText
end
System() = System(Nothing, Nothing, Mouse(), Keyboard(), InputText())



"""
# App 
`g = App()` で初期化 \\
`g.scene.w` でウインドウサイズを取得 \\
`g.scene.center` でウインドウの中心座標を取得 \\
`g.scene.t` で現在時間を取得 \\
`g.scene.dt` で前フレームとの時間差を取得 \\
`g.system.keyboard.scans[:w].down` でキーボードのwが押されたかを取得 \\
※ただし、`register_keys!(g, [..., :w, ...])` が実行されている必要がある。 \\
`g.scene.timing[0.5]`は0.5秒ごとにtrueになるタイミングを与える。 \\
"""
mutable struct App
    info::Info
    scene::Scene
    system::System
    main::Function
end
export App
App() = App(Info(), Scene(), System(), () -> ())


intround = (x -> Int(round(x)))
intfloor = (x -> Int(floor(x)))
intceil  = (x -> Int(ceil(x)))
rot_2d_matrix(θ::Real) = [cos(θ) -sin(θ); sin(θ) cos(θ)]



"""
キーボードキー登録
"""
function register_key!(g::App, s::Symbol)
    push!(g.system.keyboard.keys, s)
    g.system.keyboard.scans[s] = Button(false, false)
end
export register_key!

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
    ttf_init()
    mix_init()
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
    sdl_close.(reserve_close)
    sdl_destroy.(reserve_destroy)
    sdl_destroy(win)
    sdl_destroy(renderer)
    mix_quit()
    ttf_quit()
    sdl_quit()
end
export endapp



"""
ゲーム実行関数
"""
function runapp(g::App, args...; kwargs...)
    beginapp(g)
    g.main(args...; kwargs...)
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
    if g.scene.dt > 0.1 g.scene.dt = 0.1
    end
    t_old = time()
    g.scene.t = t - t0
    for key = g.scene.timing.keys
        g.scene.timing.timings[key] = false
        if t - g.scene.timing.timers[key] > key
            g.scene.timing.timings[key] = true
            g.scene.timing.timers[key] = t
        end
    end
    for s = g.system.keyboard.keys
        g.system.keyboard.scans[s].down = false
        g.system.keyboard.scans[s].up = false
    end
    g.system.mouse.lbutton.down = false
    g.system.mouse.rbutton.down = false
    g.system.mouse.wheel.is_wheeled = false
    g.system.mouse.wheel.dx = [0, 0]
    if length(g.system.inputtext.text) > g.system.inputtext.textlength # テキストが長くなり過ぎたら削除
        g.system.inputtext.text = ""
    end
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
        elseif sdl_event_is(e, :SDL_MOUSEWHEEL)
            g.system.mouse.wheel.dx = [Int(e.wheel.x), Int(e.wheel.y)]
            g.system.mouse.wheel.is_wheeled = true
        elseif sdl_event_is(e, :SDL_TEXTINPUT)
            str = String(NTuple32Cchar(e.text.text))
            g.system.inputtext.text *= str
        elseif sdl_event_is(e, :SDL_TEXTEDITING)
            g.system.inputtext.composition = String(NTuple32Cchar(e.edit.text))
            g.system.inputtext.cursor      = e.edit.start + 1
            g.system.inputtext.select_len  = e.edit.length
        end
    end
    g.system.mouse.x = sdl_mouse_position()
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


