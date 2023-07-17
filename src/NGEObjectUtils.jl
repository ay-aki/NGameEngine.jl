"""
scale functions
"""
function scale!(val::Rect, a)
    val.w = a .* val.w
end
function scale!(val::Union{Image, Moji}, a)
    scale!(val.tex.rect, a)
end
export scale!



"""
rotate functions
"""
function rotate!()
    ;
end



"""
# resize functions
ImageやMojiの描画サイズを設定します。
"""
function Base.resize!(val::Texture, w)
    val.rect.w = w
end
function Base.resize!(val::Image, w)
    resize!(val.tex, w)
end
export resize!



"""
# cut!
元画像のうち、切り取るサイズ`w`とオフセット`offset`を与え、ImageやMojiを特定の大きさで切ります。\\
特定のサイズのグリッド状にしたい場合は縦横の要素数`siz`を与えてください。
```
img  = Image(file)
imgs = cut(img, [3, 5])
```
"""
function cut!(tex::Texture, rect0::Rect)
    tex.rect0 = rect0
end
cut!(val::Union{Image, Moji}, rect0) = cut!(val.tex, rect0)
function cut(val::Union{Image, Moji}, siz::AbstractArray)
    n, m = siz
    vals = fill(val, (n, m))
    w = (val.tex.rect0.w - val.tex.rect0.x) .÷ siz
    for i = 1:n for j = 1:m
        newval = copy(val)
        x = val.tex.rect0.x + ([i, j] .- 1) .* w
        cut!(newval, Rect(x, w))
        val.x = [0, 0]
        val.tex.rect.w = w
        vals[i, j] = newval
    end end
    return vals
end
export cut, cut!







"""
_draw_ functions 
"""
_draw_(emp::Empty) = begin ; end
function _draw_(line::Line; linewidth = 1)
    sdl_render_draw_abstract_line(renderer, line.x, line.vec, linewidth, 0)
end
function _draw_(circ::Circle; is_filled = false)
    r, r0 = [circ.r, circ.r], [circ.r, circ.r]
    if is_filled  r0 = [0, 0]  end
    sdl_render_draw_abstract_circle(renderer, circ.o, r0, r, 0)
end
function _draw_(ell::Ellipse; is_filled = true)
    r, r0 = ell.r, ell.r
    if is_filled  r0 = [0, 0]  end
    sdl_render_draw_abstract_circle(renderer, ell.o, r0, r, 0)
end
function _draw_(donut::Donut)
    r, r0 = donut.r, donut.r0
    if typeof(r)  <: Real r  = [ r, r] end
    if typeof(r0) <: Real r0 = [r0,r0] end
    sdl_render_draw_abstract_circle(renderer, donut.o, r0, r, 0)
end
function _draw_(rect::Rect; is_filled = false, linewidth = 1)
    x = Int.(round.(rect.x))
    w = Int.(round.(rect.w))
    sdl_render_draw_abstract_rect(renderer, x, w, linewidth, is_filled)
end
function _draw_(points::Vector{Vector{Integer}})
    sdl_render_draw_points(renderer, points)
end
function _draw_(pat::Pattern)
    m, n = size(pat.X)
    for i = 1:n
        points = fill(zeros(Integer, 2), m)
        cnt = 1
        for j = 1:m
            if pat.X[j, i]
                x = pat.x + [i, j] .- 1
                points[cnt] = Int.(round.(x))
                cnt += 1
            end
        end
        _draw_(points[1:cnt-2])
    end
end
function _draw_(tex::Texture)
    x0 = Int.(round.(tex.rect0.x))
    w0 = Int.(round.(tex.rect0.w))
    x  = Int.(round.(tex.rect.x))
    w  = Int.(round.(tex.rect.w))
    sdl_render_copy(
        renderer, tex.texture, 
        x0, w0, # コピー元
        x , w   # コピー先
    )
end
function _draw_(val::Union{Image, Moji})
    _draw_(val.tex)
end
function _draw_(gr::Grid)
    n, m = gr.siz
    for i = 1:n for j = 1:m
        draw(gr[i, j])
    end end
end
"""
# draw functions
"""
function draw(
      val::Union{Line, Rect, Circle, Donut, Ellipse, Pattern}
    ; color = RGBA(1, 1, 1, 1)
    , kwargs...
)
    color_r = sdl_get_render_draw_color(renderer)
    sdl_set_render_draw_color(renderer, color)
    _draw_(val; kwargs...)
    sdl_set_render_draw_color(renderer, color_r)
end
function draw(; color = RGBA(0, 0, 0, 1))
    color_r = sdl_get_render_draw_color(renderer)
    sdl_set_render_draw_color(renderer, color)
    sdl_render_clear(renderer)
    sdl_set_render_draw_color(renderer, color_r)
end
function draw(val::Union{Image, Moji}; x = Nothing, kwargs...)
    _draw_(val; kwargs...)
end
function draw(str::AbstractString, x; font = Nothing, color = RGBA(1, 1, 1, 1), kwargs...)
    if font != Nothing
        moji = Moji(str, font; color = color)
    else
        moji = Moji(str; color = color)
    end
    moji.tex.rect.x = x
    draw(moji; kwargs...)
    # テクスチャを開放
    sdl_destroy(moji.tex.texture)
    pop!(reserve_destroy)
    moji = Nothing
end
function draw(val, x::AbstractArray; kwargs...)
    x, val.x = val.x, x
    draw(val)
    x, val.x = val.x, x
end
draw(gr::Grid; kwargs...) = _draw_(gr; kwargs...)
draw(em::Empty) = _draw_(em)
export draw

