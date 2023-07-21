


"""
外積で線の領域が線に対して異なるか同じかを返す。
"""
function judge_cross_each(v, v1, v2)
    v_  = vcat(v, [0])
    v1_ = vcat(v1, [0])
    v2_ = vcat(v2, [0])
    s = cross(v_, v1_)[3]
    t = cross(v_, v2_)[3]
    return (sign(s*t) == -1) ? true : false
end
"""
# judge_cross (線分の交差判定)
ABとCDが異なる領域に存在すると交差していると言える。
```
# eaxmple1 
x0, x1 = [0, 0], [100, 100]; y0, y1 = [100, 0], [90, 60]; 
judge_cross(x0, x1, y0, y1) # => false
# example2
x0, x1 = [0, 0], [100, 100]; y0, y1 = [100, 0], [10, 60]; 
judge_cross(x0, x1, y0, y1) # => true
```
"""
function judge_cross(x0, x1, y0, y1)
    each_1 = judge_cross_each(x1 - x0, y0 - x0, y1 - x0)
    each_2 = judge_cross_each(y1 - y0, x0 - y0, x1 - y0)
    return each_1 & each_2
end


"""
rectのための関数
"""
function _each_intersects!(matview, sh, v::AbstractArray)
    left , upper = sh.topleft .< v
    right, lower = v .< sh.bottomright
    matview .&= [
        left & upper  right & upper; 
        left & lower  right & lower
    ]
end
function _map_intersects(sh::Rect, b_sh::Rect)
    ret = ones(Bool, 3, 3)
    _each_intersects!(view(ret, 1:2, 1:2), sh, b_sh.topleft)
    _each_intersects!(view(ret, 1:2, 2:3), sh, b_sh.topright)
    _each_intersects!(view(ret, 2:3, 1:2), sh, b_sh.bottomleft)
    _each_intersects!(view(ret, 2:3, 2:3), sh, b_sh.bottomright)
    return ret
end
function _map_intersects(x::Vector, b_sh::Rect)
    left , top    = b_sh.topleft
    right, bottom = b_sh.bottomright
    ret = ones(Bool, 3, 3)
    ret[1:3, 1] .&= (x[1] < left)
    ret[1:3, 2] .&= (left <= x[1] <= right)
    ret[1:3, 3] .&= (right < x[1])
    ret[1, 1:3] .&= (x[2] < top)
    ret[2, 1:3] .&= (top <= x[2] <= bottom)
    ret[3, 1:3] .&= (bottom < x[2])
    return ret
end
function _intersectsmat_to_s(t, s::Symbol)
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

function _intersects_circle_vs_rect_cross(sh::Circle, b_sh::Rect)
    dis = abs.(sh.o - b_sh.center)
    if any(dis .>  (b_sh.w .÷ 2 .+ sh.r))
        return false
    end
    if any(dis .<= (b_sh.w .÷ 2)) 
        return true
    end
    return (sum((dis - b_sh.w .÷ 2) .^ 2) <= sh.r ^ 2)
end

function _intersects_circle_vs_rect(sh::Circle, b_sh::Rect)
    cross = _intersects_circle_vs_rect_cross(sh, b_sh)
    it_rect = Intersects(Rect(sh), b_sh)
    top   = cross & it_rect.top
    bottom= cross & it_rect.bottom
    left  = cross & it_rect.left
    right = cross & it_rect.right
    #=
    top   = cross & (dis[2] <= 0)
    bottom= cross & (dis[2] >= 0)
    left  = cross & (dis[1] <= 0)
    right = cross & (dis[1] >= 0)=#
    return cross, top, bottom, left, right
end




"""
# Intersects
```
it_line_vs_line = Intersects(line, b_line)
it_line_vs_line.cross # 交差しているか？

```
"""
struct Intersects{T1, T2} shape::T1; b_shape::T2; _dict_::Dict end
export Intersects



# Line vs Line
function Intersects(sh::Line, b_sh::Line)
    _dict_ = Dict{Symbol, Union{Real, AbstractArray}}()
    x0, x1 = sh.x, sh.x + sh.vec
    y0, y1 = b_sh.x, b_sh.x + b_sh.vec
    _dict_[:cross] = judge_cross(x0, x1, y0, y1)
    return Intersects(sh, b_sh, _dict_)
end
Base.any(it::Intersects{Line, Line}) = it.cross
# Rect vs Rect
function Intersects(sh::Rect, b_sh::Rect)
    _dict_ = Dict{Symbol, Union{Real, AbstractArray}}()
    _mat_ = _map_intersects(sh, b_sh)
    _dict_[:_mat_] = _mat_
    for name in [:top, :bottom, :left, :right, :bounded, :bounds]
        _dict_[name] = _intersectsmat_to_s(_mat_, name)
    end
    return Intersects(sh, b_sh, _dict_)
end
Base.any(it::Intersects{Rect, Rect}) = it.left | it.right | it.top | it.bottom
# Circle vs Circle
function Intersects(sh::Circle, b_sh::Circle)
    _dict_ = Dict{Symbol, Union{Real, AbstractArray}}()
    touch = (norm(sh.o - b_sh.o) < (sh.r + b_sh.r))
    _dict_[:cross] = _dict_[:touch] = touch
    return Intersects(sh, b_sh, _dict_)
end
Base.any(it::Intersects{Circle, Circle}) = it.cross
# Circle vs Vector
function Intersects(sh::Circle, x::Vector)
    _dict_ = Dict{Symbol, Union{Real, AbstractArray}}()
    cross = (sh.r < norm(x - sh.o))
    _dict_[:cross] = cross
    return Intersects(sh, x, _dict_)
end
Intersects(x::Vector, sh::Circle) = Intersects(sh, x)
Base.any(it::Intersects{Circle, Vector}) = it.cross
# Vector vs Rect
function Intersects(x::Vector, b_sh::Rect)
    _dict_ = Dict{Symbol, Union{Real, AbstractArray}}()
    _dict_[:_mat_] = _map_intersects(x, b_sh)
    _dict_[:cross] = _mat_[2, 2]
    return Intersects(x, b_sh, _dict_)
end
Intersects(sh::Rect, x::Vector) = Intersects(x, sh)
Base.any(it::Intersects{Vector, Rect}) = it.cross
# Circle vs Rect
function Intersects(sh::Circle, b_sh::Rect)
    _dict_ = Dict{Symbol, Union{Real, AbstractArray}}()
    cross, top, bottom, left, right = _intersects_circle_vs_rect(sh, b_sh)
    _dict_[:cross] = cross
    _dict_[:top] = top
    _dict_[:bottom] = bottom
    _dict_[:left] = left
    _dict_[:right] = right
    return Intersects(sh, b_sh, _dict_)
end
function Intersects(sh::Rect, b_sh::Circle)
    _dict_ = Dict{Symbol, Union{Real, AbstractArray}}()
    cross, bottom, top, right, left = _intersects_circle_vs_rect(b_sh, sh)
    _dict_[:cross] = cross
    _dict_[:top] = top
    _dict_[:bottom] = bottom
    _dict_[:left] = left
    _dict_[:right] = right
    return Intersects(sh, b_sh, _dict_)
end
Base.any(it::Intersects{Circle, Rect}) = it.cross
# 定義できない場合は、図形を囲む長方形領域を比較する。
function Intersects(sh, b_sh)
    Intersects(Rect(sh), Rect(b_sh))
end





function Base.getproperty(itsh::Intersects, name::Symbol)
    if name in fieldnames(Intersects)
        return getfield(itsh, name)
    else
        return itsh._dict_[name]
    end
end


