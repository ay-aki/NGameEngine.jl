
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
    ipos= [
        gr[rand(1:gr.x[1]), rand(1:gr.x[2])].lm
        for i = 1:15
    ]
    # マウスで画像を設置する
    lpos= []
    # マウスの位置に表示する画像
    img_tf = img
    # 画像の拡大率
    a = [1.0, 1.0]
    while update!(g)
        # 背景色を白とする
        draw(c=RGBA(1, 1, 1, 1))
        # グリッドを表示する
        draw(gr, [0, 0], c=RGBA(1, 0, 0, 1))
        # マウスの位置がlower-middleになるときの描写用座標
        x_mouse = g.system.mouse.x
        # マウスの場所に画像を表示する
        if g.system.mouse.lbutton.down  push!(lpos, x_mouse)
        end
        if g.system.mouse.wheel.is_wheeled == true
            if     g.system.mouse.wheel.dx[2] > 0  a = 1.1 * a
            elseif g.system.mouse.wheel.dx[2] < 0  a = 0.9 * a
            end
        end
        img_tf = Tf(a=a) * img
        draw(img_tf, Boundary(img_tf.w, lm=x_mouse).ul)
        (x -> draw(img_tf, x)).((x -> Boundary(img_tf.w, lm = x).ul).(ipos))
        (x -> draw(img_tf, x)).((x -> Boundary(img_tf.w, lm = x).ul).(lpos))
        sleep(0.01)
    end
end


function app_4()
    gr   = Grid()
    img  = Tf(a=0.1) * Image("..\\assets\\img_files\\sample1.png")
    gr2  = Grid(w=img.w0 .÷ [12, 3], x=[12, 3])
    imgs = (x -> cut_texture(img, x)).(gr2)
    (x -> resize_texture!(x, [32, 32])).(imgs)

    while update!(g)
        draw()
        draw(gr, [0, 0])
        draw(imgs[9, 1], gr[5, 7].ul)
        sleep(0.1)
    end
end



function app_5()
    circ = Circle(r=200)
    while update!(g)
        draw(circ, g.system.mouse.x, pin = :mm)
        sleep(0.01)
    end
end



g.main = app_5

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