

#=
Button
=#
abstract type Button end

mutable struct SimpleButton <: Button x; str; rect::Rect end
export SimpleButton
SimpleButton(rect::Rect) = SimpleButton([0, 0], rect)


function _draw_(val::SimpleButton)
    
end

