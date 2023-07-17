


"""
外積で線の領域が線に対して異なるか同じ課を返す。
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


Shape = Union{Rect, Line, Vector}#, Circle}






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










"""
# Intersects
```
it_line_vs_line = Intersects(line, b_line)
it_line_vs_line.cross # 交差しているか？

```
"""
struct Intersects shape; b_shape; _dict_::Dict end
export Intersects
# 線分のクロス判定
function Intersects(sh::Line, b_sh::Line)
    _dict_ = Dict{Symbol, Union{Real, AbstractArray}}()
    x0, x1 = sh.x, sh.x + sh.vec
    y0, y1 = b_sh.x, b_sh.x + b_sh.vec
    _dict_[:cross] = judge_cross(x0, x1, y0, y1)
    return Intersects(sh, b_sh, _dict_)
end
# 長方形領域の接触判定
function Intersects(sh::Rect, b_sh::Rect)
    _dict_ = Dict{Symbol, Union{Real, AbstractArray}}()
    _mat_ = _map_intersects(sh, b_sh)
    _dict_[:_mat_] = _mat_
    for name in [:top, :bottom, :left, :right, :bounded, :bounds]
        _dict_[name] = _intersectsmat_to_s(_mat_, name)
    end
    return Intersects(sh, b_sh, _dict_)
end
# 点と長方形領域の接触判定
function Intersects(x::Vector, b_sh::Rect)
    _dict_ = Dict{Symbol, Union{Real, AbstractArray}}()
    _dict_[:_mat_] = _map_intersects(x, b_sh)
    _dict_[:bounded] = _mat_[2, 2]
    return Intersects(x, b_sh, _dict_)
end
function Intersects(sh::Rect, x::Vector)
    _dict_ = Dict{Symbol, Union{Real, AbstractArray}}()
    _dict_[:_mat_] = _map_intersects(x, sh)
    _dict_[:bounds] = _mat_[2, 2]
    return Intersects(sh, x, _dict_)
end
# 円の接触判定
function Intersects(sh::Circle, b_sh::Circle)
    _dict_ = Dict{Symbol, Union{Real, AbstractArray}}()
    touch = (norm(sh.o - b_sh.o) < (sh.r + b_sh.r))
    _dict_[:touch] = touch
    return Intersects(sh, b_sh, _dict_)
end
# Expanded_Object
#=
function Intersects(sh::Expand_Object, b_sh::Expand_Object)
    v1, v2 = shape_of(sh), shape_of(b_sh)
    return Intersects(v1, v2)
end
=#



function Base.getproperty(itsh::Intersects, name::Symbol)
    if name in fieldnames(Intersects)
        return getfield(itsh, name)
    else
        return itsh._dict_[name]
    end
end
function Base.any(it::Intersects)
    type1, type2 = typeof(it.shape), typeof(it.shape) 
    if     type1 == type2 == Rect
        return it.top | it.bottom | it.left | it.right
    elseif type1 == type2 == Line
        return it.cross
    elseif (type1 == Vector) & (type2 == Rect)
        return it.bounded
    elseif (type1 == Rect) & (type2 == Vector)
        return it.bounds
    elseif type1 == type2 == Circle
        return it.touch
    else
        @error("NGE: error Base.any(Intersects)")
    end
end



#=
it = Intersects(rect, b_rect)
any(it) # どこかが触れている
it.top # rectの上部がb_rectと触れている
   bottom
   left
   right
it.bounds # rectがb_rectを含む
it.bounded # rectがb_rectに含まれる

it = Intersects(line, line)
it.cross

it = Intersects(rect, [x1, x2])
it.bounds # 点を含む

it = Intersects([x1, x2], rect)
it.bounded # 点が含まされる(上記の逆)

any(it) # どこがが触れている
=#