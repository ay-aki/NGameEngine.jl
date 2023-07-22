

module NGESDL
using SimpleDirectMediaLayer
using SimpleDirectMediaLayer.LibSDL2
using Colors
using LinearAlgebra



#=
...
=#
intround      = (x -> Int(round(x)))
intfloor      = (x -> Int(floor(x)))
intceil       = (x -> Int(ceil(x)))
uint8round    = (x -> UInt8(round(x)))
uint8round255 = (x -> UInt8(round(x*255)))
rot_2d_matrix(θ::Real) = [cos(θ) -sin(θ); sin(θ) cos(θ)]



#=
Core functions
=#
function sdl_init()
    SDL_GL_SetAttribute(SDL_GL_MULTISAMPLEBUFFERS, 16)
    SDL_GL_SetAttribute(SDL_GL_MULTISAMPLESAMPLES, 16)
    SDL_Init(SDL_INIT_EVERYTHING)
end
export sdl_init
# 
sdl_quit() = SDL_Quit()
export sdl_quit
sdl_create_window(title, v_size) = SDL_CreateWindow(title, SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, v_size[1], v_size[2], SDL_WINDOW_OPENGL)
sdl_create_renderer(win) =  SDL_CreateRenderer(win, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC)
sdl_window_resizable(win) = SDL_SetWindowResizable(win, SDL_TRUE)
function sdl_create_window_and_renderer(title, v_size)
    win = sdl_create_window(title, v_size)
    sdl_window_resizable(win) # 
    renderer = sdl_create_renderer(win)
    return win, renderer
end
export sdl_create_window_and_renderer
# 
sdl_event_init() = Ref{SDL_Event}()
export sdl_event_init
# 
function sdl_poll_event(event)
    flag_end_loop = SDL_PollEvent(event) |> Bool
    return event[], !flag_end_loop
end
export sdl_poll_event
# 
function sdl_poll_events(event)
    evts = []
    while true
        evt, flag_poll_event = sdl_poll_event(event)
        if flag_poll_event 
            break
        end
        push!(evts, evt)
    end
    return evts
end
export sdl_poll_events



#=
[-29, -127, -126, 0]

sdl_NTuple4_to_char([-28, -69, -78])
sdl_NTuple4_to_char([-23, -106, -109])

sdl_NTuple32_to_string([-28, -69, -78, -23, -106, -109, 0, 28, 0, 0, 0, 0, 12, 0, 0, 0])

function sdl_NTuple4_to_char(vec)
    f = x -> (x < 0) ? 256 + x : x
    c = String(collect(UInt8.(f.(vec))))[1]
    return c
end

function sdl_NTuple32_to_string(vec)
    s = ""
    for i = 1:4
        c = sdl_NTuple4_to_char(vec[(4*(i-1)+1):(4*i)])
        println(vec[(4*(i-1)+1):(4*i)], c)
        # if  c == '\0' break end
        s *= c#(isprint(c)) ? c : ""
    end
    return s
end=#


function sdl_NTuple32_to_string(vec)
    ret = ""
    f = x -> (x < 0) ? 256 + x : x
    str = String(collect(UInt8.(f.(vec))))
    i = 1
    while (i <= 32) & isprint(str[i]) & isvalid(str[i])
        ret *= str[i]
        i = nextind(str, i)
    end
    return ret
end


struct NTuple32Cchar ctext end
export NTuple32Cchar
function Base.String(text::NTuple32Cchar)
    return sdl_NTuple32_to_string(text.ctext)
end



#=
draw functions
=# 
sdl_set_render_draw_color(renderer, c::AbstractRGBA) = SDL_SetRenderDrawColor(renderer, UInt8(round(c.r*255)), UInt8(round(c.g*255)), UInt8(round(c.b*255)), UInt8(round(c.alpha*255)))
sdl_set_render_draw_color(renderer, v::AbstractArray) = SDL_SetRenderDrawColor(renderer, UInt8(round(v[1])), UInt8(round(v[2])), UInt8(round(v[3])), UInt8(round(v[4])))
export sdl_set_render_draw_color
#
function sdl_get_render_draw_color(renderer)
    r, g, b, a = Ref{UInt8}(0), Ref{UInt8}(0), Ref{UInt8}(0), Ref{UInt8}(0)
    SDL_GetRenderDrawColor(renderer, r, g, b, a)
    return RGBA(r[]/255, g[]/255, b[]/255, a[]/255)
end
export sdl_get_render_draw_color
# 
sdl_render_draw_point(renderer, x) = SDL_RenderDrawPoint(renderer, Cint(x[1]), Cint(x[2]))
export sdl_render_draw_point
# 
sdl_render_draw_points(renderer, points) = SDL_RenderDrawPoints(renderer, (x -> SDL_Point(x[1], x[2])).(points), length(points))
# sdl_render_draw_points(renderer, points) = sdl_render_draw_point.(renderer, points)# SDL_RenderDrawPoints(renderer, Ref(points), length(points)) # SDL_RenderDrawPoints(renderer, (x -> Cint.(x)).(points), length(points))
export sdl_render_draw_points
# 
sdl_render_draw_line(renderer, x, y) = SDL_RenderDrawLine(renderer, x[1], x[2], y[1], y[2])
export sdl_render_draw_line
# 
sdl_render_draw_lines(renderer, points) = SDL_RenderDrawLines(renderer, (x -> Cint.(x)).(points), length(points))
export sdl_render_draw_lines
function sdl_render_draw_rect(renderer, x, w)
    rect = Ref(SDL_Rect(x[1], x[2], w[1], w[2]))
    SDL_RenderDrawRect(renderer, rect)
end
export sdl_render_draw_rect
# 
function sdl_render_draw_abstract_line(renderer, x, lv, lw, θ)
    lv = rot_2d_matrix(θ::Real) * lv
    if     lw == 1
        sdl_render_draw_line(renderer, x, x+lv)
    elseif lw >  1
        nv  = [+1, -1] .* lv
        nve = nv / max(nv[1], nv[2])
        w2 = floor(lw / 2)
        for i = - w2:(lw - w2)
            xi = Int.(floor.(x + i*nve))
            vi = Int.(floor.(xi + lv))
            sdl_render_draw_line(renderer, xi, vi)
        end
    end
end
export sdl_render_draw_abstract_line
# 
function sdl_render_draw_fill_rect(renderer, x, w)
    rect = Ref(SDL_Rect(x[1], x[2], w[1], w[2]))
    SDL_RenderFillRect(renderer, rect)
end
export sdl_render_draw_fill_rect
# 
function sdl_render_draw_abstract_rect(renderer, x, w, width, is_filled)
    # 内部を埋める
    if     is_filled
        sdl_render_draw_fill_rect(renderer, x, w)
    # 内部なし
    elseif width == 1
        sdl_render_draw_rect(renderer, x, w)
    # 枠付き
    elseif width >  1
        for i = 1:width 
            sdl_render_draw_rect(renderer, x + i * ones(2), w - 2*i * ones(2))
        end
    end
end
export sdl_render_draw_abstract_rect
# 
function sdl_render_draw_circle_curve(renderer, x, r, θ)
    R = rot_2d_matrix(θ)
    n = 3 * Int.(round(maximum(r)))
    f = (θ -> Int.(round.(x + r .* (R * [cos(θ), sin(θ)]))))
    p = f.(range(0, 2π, n))
    sdl_render_draw_points(renderer, p)
end
export sdl_render_draw_circle_curve
# 
function sdl_render_draw_circle_donut(renderer, x, r0, r1, θ)
    cnt = 1
    points = fill([0, 0], prod(2 * r1))
    rx   , ry    = r1
    r_inx, r_iny = r0
    for i = -rx:rx
        for j = -ry:ry
            if (r_inx/rx)^2 + (r_iny/ry)^2 <= (i/rx)^2 + (j/ry)^2 <= 1
                # xx = x + r1 + [i, j]
                xx = x + [i, j]
                points[cnt] = intround.(xx)
                cnt = cnt + 1
            end
        end
    end
    sdl_render_draw_points(renderer, points[begin:cnt-1])
end
export sdl_render_draw_circle_donut
# 位置x 内径r0 外径r1 回転θ
function sdl_render_draw_abstract_circle(renderer, x, r0, r1, θ)
    # 楕円（線）
    if r0 == r1
        sdl_render_draw_circle_curve(renderer, x, r0, θ)
    # 楕円（ドーナツ）
    else
        sdl_render_draw_circle_donut(renderer, x, r0, r1, θ)
    end
end
export sdl_render_draw_abstract_circle
# 
function sdl_render_copy(renderer, texture, rect::SDL_Rect, drect::SDL_Rect)
    ref_rect  = Ref(rect)
    ref_drect = Ref(drect)
    SDL_RenderCopy(renderer, texture, ref_rect, ref_drect)
    return ref_drect[]
end
function sdl_render_copy(renderer, texture, x1::AbstractArray, w1::AbstractArray, x2::AbstractArray, w2::AbstractArray)
    rect  = SDL_Rect(x1[1], x1[2], w1[1], w1[2])
    drect = SDL_Rect(x2[1], x2[2], w2[1], w2[2])
    return sdl_render_copy(renderer, texture, rect, drect)
end
function sdl_render_copy(renderer, texture, rect::SDL_Rect)
    dest_ref = Ref(rect) # rect = SDL_Rect(x, y, w, h))
    SDL_RenderCopy(renderer, texture, C_NULL, dest_ref)
    return dest_ref[]
end
function sdl_render_copy(renderer, texture, x::AbstractArray, w::AbstractArray)
    rect = SDL_Rect(x[1], x[2], w[1], w[2])
    return sdl_render_copy(renderer, texture, rect)
end
export sdl_render_copy
#
sdl_render_clear = SDL_RenderClear
sdl_render_present = SDL_RenderPresent
export sdl_render_present, sdl_render_clear
# 
function sdl_destroy_window_and_renderer(win, renderer)
    SDL_DestroyRenderer(renderer)
    SDL_DestroyWindow(win)
end
export sdl_destroy_window_and_renderer
# 
sdl_destroy(renderer::Ptr{SDL_Renderer}) = SDL_DestroyRenderer(renderer)
sdl_destroy(win::Ptr{SDL_Window}) = SDL_DestroyWindow(win)
export sdl_destroy
# 
img_load(file) = IMG_Load(file)
sdl_create_texture_from_surface(renderer, surface) = SDL_CreateTextureFromSurface(renderer, surface)
"""
テクスチャを開放
"""
sdl_free_surface(surface) = SDL_FreeSurface(surface)
export img_load, sdl_create_texture_from_surface, sdl_free_surface
"""
テクスチャのサイズを得る
"""
function sdl_query_texture(texture)
    w_ref, h_ref = Ref{Cint}(0), Ref{Cint}(0)
    SDL_QueryTexture(texture, C_NULL, C_NULL, w_ref, h_ref)
    return w_ref[], h_ref[]
end
export sdl_query_texture
"""
ウインドウからサーフェスを生成 \\
surface = sdl_get_window_surface(window)
"""
sdl_get_window_surface(window) = SDL_GetWindowSurface(window)
export sdl_get_window_surface
"""
sdl_map_rgba(surface.format, [255, 0, 0, 255]) \\
sdl_map_rgba(surface.format, RGBA(255, 0, 0, 255)) \\
"""
sdl_map_rgba(format, v::AbstractArray) = SDL_MapRGBA(format,  uint8round(v[1]), uint8round(v[2]), uint8round(v[3]), uint8round(v[4]))
sdl_map_rgba(format, c::AbstractRGBA) = SDL_MapRGBA(format, uint8round255(c.r), uint8round255(c.g), uint8round255(c.b), uint8round255(c.alpha))
export sdl_map_rgba



#=
Core functions 2
=#
function sdl_get_window_size(win)
    w, h = Int32[0],Int32[0]
    SDL_GetWindowSize(win, w, h)
    return w[], h[]
end
export sdl_get_window_size
function sdl_get_drawable_size(win)
    w, h = Int32[0],Int32[0]
    SDL_GL_GetDrawableSize(win, w, h)
    return w[], h[]
end
export sdl_get_drawable_size
sdl_event_is(e, s::Symbol) = (e.type == eval(s))
export sdl_event_is
sdl_event_is_quit(e) = (e.type == SDL_QUIT)
export sdl_event_is_quit
# 
function sdl_mouse_position()
    x, y = Int[1], Int[1]
    SDL_GetMouseState(pointer(x), pointer(y))
    return [x[1], y[1]]
end
export sdl_mouse_position
# 
function sdl_scancode_is(e, s::Symbol)
    code = Nothing
    st = string(s)
    if length(st) == 1
        if only(st) in 'a':'z' st = uppercase(st)
        elseif st == "↑" st = "UP"
        elseif st == "↓" st = "DOWN"
        elseif st == "→" st = "RIGHT"
        elseif st == "←" st = "LEFT"
        end
    end
    ss = Symbol("SDL_SCANCODE_" * st)
    try
        code = getproperty(SimpleDirectMediaLayer.LibSDL2, ss)
    catch
        @error "unknown key"
        code = -1
    end
    return e.key.keysym.scancode == code
end
export sdl_scancode_is
function sdl_mousebutton_is(e, s::Symbol)
    return e.button.button == eval(s)
end
export sdl_mousebutton_is
sdl_delay = SDL_Delay
export sdl_delay
sdl_destroy(texture::Ptr{SDL_Texture}) = SDL_DestroyTexture(texture)
export sdl_destroy



#=
TTF functions
=#
ttf_init() = TTF_Init()
export ttf_init
ttf_quit() = TTF_Quit()
export ttf_quit
ttf_open_font(file) = TTF_OpenFont(file, 20)
ttf_open_font(file, pointsize) = TTF_OpenFont(file, pointsize)
export ttf_open_font
ttf_close_font(font) = TTF_CloseFont(font)
export ttf_close_font
sdl_close(font::Ptr{TTF_Font}) = ttf_close_font(font)
sdl_destroy(font::Ptr{TTF_Font}) = ttf_close_font(font)
export sdl_close
ttf_render_UTF8_blanded(font, str, v::AbstractArray) = TTF_RenderUTF8_Blended(
    font, str, 
    SDL_Color(
        UInt8(round(v[1])), UInt8(round(v[2])), 
        UInt8(round(v[3])), UInt8(round(v[4]))
    )
)
ttf_render_UTF8_blanded(font, str, c::AbstractRGBA) = ttf_render_UTF8_blanded(
    font, str, 
    [c.r*255, c.g*255, c.b*255, c.alpha*255]
)
export ttf_render_UTF8_blanded
ttf_set_font_hinting(font) = TTF_SetFontHinting(font, TTF_HINTING_NORMAL)
export ttf_set_font_hinting



#=
Audio functions
=#
function mix_open_audio(frequency, format, channels, chunksize)
    flag = Mix_OpenAudio(frequency, format, channels, chunksize)
    if flag == -1  @error "NGE: mix open failed"
    end
end
mix_open_audio() = mix_open_audio(MIX_DEFAULT_FREQUENCY, MIX_DEFAULT_FORMAT, MIX_DEFAULT_CHANNELS, 4096)
export mix_open_audio
mix_init() = mix_open_audio()
export mix_init
mix_quit() = Mix_CloseAudio()
export mix_quit
mix_volume_music(volume) = Mix_VolumeMusic(volume)
export mix_volume_music
mix_load_mus(file) = Mix_LoadMUS(file)
export mix_load_mus
function mix_play_music(mus::Ptr{Mix_Music}; loops = 0)
    Mix_PlayMusic(mus, loops)
end
# mix_play_music(mus::Ptr{Mix_Music}; loop = false) = Mix_PlayMusic(mus, Int(loop))
export mix_play_music
sdl_destroy(mus::Ptr{Mix_Music}) = Mix_FreeMusic(mus)



end

