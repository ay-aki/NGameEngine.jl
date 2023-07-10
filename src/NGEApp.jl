


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

mutable struct Wheel
    dx::AbstractArray
    is_wheeled::Bool
    Wheel(dx, is_wheeled) = new(dx, is_wheeled)
    Wheel() = Wheel([0, 0], false)
end

mutable struct Button
    down::Bool
    up::Bool
    Button(down, up) = new(down, up)
    Button() = Button(false, false)
end

mutable struct Mouse
    x::AbstractArray
    lbutton::Button
    rbutton::Button
    wheel::Wheel
    Mouse(x, lbutton, rbutton, wheel) = new(x, lbutton, rbutton, wheel)
    Mouse() = Mouse([-1, -1], Button(), Button(), Wheel())
end
export Mouse

mutable struct Keyboard
    keys  # 取得したいキーのリスト
    scans # キーに対応するフラグのリスト
    Keyboard() = new([], Dict())
end
export Keyboard

mutable struct System
    win # 未使用 
    renderer # 未使用
    mouse::Mouse
    keyboard::Keyboard
    System() = new(Nothing, Nothing, Mouse(), Keyboard())
end
export System



"""
# App 
`g = App()` で初期化 \\
`g.scene.w` でウインドウサイズを取得 \\
`g.scene.center` でウインドウの中心座標を取得 \\
`g.scene.t` で現在時間を取得 \\
`g.scene.dt` で前フレームとの時間差を取得 \\
`g.system.keyboard.scans[:w].down` でキーボードのwが押されたかを取得 \\
※ただし、`register_keys!(g, [..., :w, ...])` が実行されている必要がある。 
"""
mutable struct App
    info::Info
    scene::Scene
    system::System
    main::Function
    App() = new(Info(), Scene(), System(), () -> ())
end
export App


intround = (x -> Int(round(x)))
intfloor = (x -> Int(floor(x)))
intceil  = (x -> Int(ceil(x)))
rot_2d_matrix(θ::Real) = [cos(θ) -sin(θ); sin(θ) cos(θ)]



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
    ttf_init()
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
    ttf_quit()
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
    g.system.mouse.wheel.is_wheeled = false
    g.system.mouse.wheel.dx = [0, 0]
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


