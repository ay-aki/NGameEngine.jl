
include("../src/NGE.jl")

using .NGE
using Colors



#= 
この内部処理は、gの構造体に代入しているが、
変数はこのファイル内部の名前区間を共有する。
当然ながら、NGE内部の名前空間は利用できない。
=# 

g = App()
register_keys!(g, [:w, :s, :a, :d, :↑, :↓, :←, :→])

function app_1()
    line = Line(v = [200, 100], lw = 4)
    circle  = Circle(r0 = [10, 50])
    circle2 = Circle(r0 = [10, 50])
    pat = Tf(a=10) * Pattern(
        X = [true false true; 
             true false true;  
             true true  true]
    )
    rect = Rectangle(w = [100, 200]) # [100, 200], RGBA(0, 0, 1, 1)
    x_me = g.scene.center
    while update!(g)
        draw(c = RGBA(0, 1, 0, 1))
        draw(Tf(a=2) * line, [100, 100]) # 図形のスケール*
        draw(Tf(θ=π/4) * line, [100, 100]) # 図形の回転^
        draw(Tf(a=[1.5, 0.5]) * circle, [0, 0], c=RGBA(1, 0, 0, 1))
        draw(rect, [0, 0])
        draw(Tf(a=0.5) * circle2, g.system.mouse.x) 
        if     g.system.keyboard.scans[:w].down x_me -= [0, 10]
        elseif g.system.keyboard.scans[:s].down x_me += [0, 10]
        elseif g.system.keyboard.scans[:a].down x_me -= [10, 0]
        elseif g.system.keyboard.scans[:d].down x_me += [10, 0]
        end
        draw(pat, x_me)
        sleep(0.05)
    end
    println(g.info)
end





g.main = app_1

runapp(g)



#=
# [REPL開発]

include("NGE.jl")

using Colors
using .NGE

g = App()

beginapp(g) # 前処理など

@update! g

line = Line(v = [100, 200])
line.c = RGBA(1, 0, 0, 1)

@update! g begin
    draw(line, [50, 50])
end

endapp(g) # 後処理など

=#

