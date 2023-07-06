
include("../src/NGE.jl")

using .NGE
using Colors
using MAT



g = App()
# キーの登録
register_keys!(g, [:w, :s, :a, :d, :↑, :↓, :←, :→])





"""
各種の図形を表示する
"""
function app_1()
    # 線の生成
    line = Line(v = [200, 100], lw = 4)
    # 円の生成
    circle  = Circle(r0 = [10, 50])
    circle2 = Circle(r0 = [10, 50])
    # パターンの生成
    pat = Tf(a=10) * Pattern(
        X = [true false true; 
             true false true;  
             true true  true]
    )
    # 長方形の生成
    rect = Rectangle(w = [100, 200]) # [100, 200], RGBA(0, 0, 1, 1)
    # 画面中央座標
    x_me = g.scene.center
    while update!(g)
        # 背景を塗る
        draw(c = RGBA(0, 1, 0, 1))
        # 図形のスケール、回転、表示
        draw(Tf(a=2) * line, [100, 100])
        draw(Tf(θ=π/4) * line, [100, 100])
        draw(Tf(a=[1.5, 0.5]) * circle, [0, 0], c=RGBA(1, 0, 0, 1))
        draw(rect, [0, 0])
        draw(pat, x_me)
        # マウス座標への表示
        draw(Tf(a=0.5) * circle2, g.system.mouse.x)
        # キーを受け取って処理
        if     g.system.keyboard.scans[:w].down x_me -= [0, 10]
        elseif g.system.keyboard.scans[:s].down x_me += [0, 10]
        elseif g.system.keyboard.scans[:a].down x_me -= [10, 0]
        elseif g.system.keyboard.scans[:d].down x_me += [10, 0]
        end
        sleep(0.05)
    end
end



"""
フォントに関するサンプル
"""
function app_2()
    line = Line(v = [200, 100], lw = 4)
    font = Font(file = "..\\assets\\ttf_files\\Noto_Sans_JP\\NotoSansJP-VariableFont_wght.ttf")
    str1 = Moji("Hello_World!", font)
    str1 = Tf(a=1.5) * str1
    str2 = Tf(c=RGBA(1, 0, 0, 0.5)) * str1
    while update!(g)
        draw(line, [0, 0], c=RGBA(1, 1, 0, 1))
        draw_at(str1, g.system.mouse.x)
        draw(str2, [300, 300])
        sleep(0.01)
    end
end



"""
画像表示のサンプル \\
クリックした場所に画像が残る。
"""
function app_3()
    # グリッドを作る
    gr  = Grid()
    # 画像を読み出す(サイズを0.1倍)
    img = Tf(a=0.1) * Image("..\\assets\\img_files\\sample0.png")
    # 15個ランダムに画像を散らす
    ipos= [gr.pos[rand(1:gr.x[1]), rand(1:gr.x[2])] for i = 1:15]
    # マウスで画像を設置する
    lpos= []
    while update!(g)
        draw(c=RGBA(1, 1, 1, 1))
        draw(gr, [0, 0], c=RGBA(1, 0, 0, 1))
        # draw((gr, g.system.mouse.x))
        #collide(
        #    (Rectangle(w=gr.w), x), 
        #    ([1,1], g.system.mouse.x)
        #)
        
        draw(img, g.system.mouse.x)
        if g.system.mouse.lbutton.down  push!(lpos, g.system.mouse.x)
        end
        if g.system.mouse.wheel.is_wheeled == true
            if     g.system.mouse.wheel.dx[2] > 0  img = Tf(a=1.1) * img
            elseif g.system.mouse.wheel.dx[2] < 0  img = Tf(a=0.9) * img
            end
        end
        (x -> draw(img, x)).(ipos)
        (x -> draw(img, x)).(lpos)
        sleep(0.01)
    end
end




g.main = app_3

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



#=
ブロック崩し

function app()
    ball_speed = [0, -480]
    ball = Circle(r = 8)
    bricks = Grid(w = [32, 8], wx=[640, 480])
    while update!(g)
        collide(bricks, ball, option=:any)
    end
end
=#