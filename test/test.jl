
include("../src/NGE.jl")

using .NGE
using Colors
using MAT




g = App()

# キーの登録
register_keys!(g, [:w, :s, :a, :d, :↑, :↓, :←, :→])



"""
# do nothing
"""
function app_0()
    ; # 何らかの初期化処理
    while update!(g)
        ; # 何らかのループ処理
    end
end



"""
# 絵文字の使用 NatoEmoji
https://fonts.google.com/noto/specimen/Noto+Emoji/glyphs
"""
function app_6()
    font = Font(SampleFiles().nge.assets.ttf_files.NotoEmoji)
    moji = Moji("🤬", font)
    while update!(g)
        draw(moji, [0, 0])
    end
end



"""
# dt秒ごとに1文字ずつ追加して表示していく（テキスト表示）
"""
function app_7()
    str = "hello everyone! my name is nge!"
    dt = 0.1
    k = 1
    while update!(g)
        if g.scene.timing[dt] & (k < length(str))
            k += 1
        end
        draw(str[1:k], [0, 0], color = RGBA(1, 0, 0, 1))
    end
end









"""
# SimpleDirectMediaLayer.jlのサンプルっぽいもの
"""
function app_3()
    register_keys!(g, [:w, :s, :a, :d, :↑, :↓, :←, :→])
    cat = Image(SampleFiles().sdl.cat)
    cat.center = g.scene.center
    cat.speed = 300
    while update!(g)
        if     g.system.keyboard.scans[:w].down | g.system.keyboard.scans[:↑].down
            cat.x[2] -= cat.speed ÷ 30
        elseif g.system.keyboard.scans[:a].down | g.system.keyboard.scans[:←].down
            cat.x[1] -= cat.speed ÷ 30
        elseif g.system.keyboard.scans[:s].down | g.system.keyboard.scans[:↓].down
            cat.x[2] += cat.speed ÷ 30
        elseif g.system.keyboard.scans[:d].down | g.system.keyboard.scans[:→].down
            cat.x[1] += cat.speed ÷ 30
        end
        draw(cat)
        sleep(1 / 60)
    end
end




function app_14()
    circ1   = Circle()
    circ1.x = [100, 100]
    circ2   = Circle()
    while update!(g)
        circ2.x = g.system.mouse.x
        it = Intersects(circ2, circ1)
        if it.touch 
            draw("intersects!", [0, 0])
        end
        draw.([circ1, circ2])
    end
end



function app_8()
    hello = Moji("Hello World!")
    hello.dx = [1, 1]
    while update!(g)
        hello.x += hello.dx
        draw(hello)
        sleep(1/100)
    end
end




"""
# 長方形型の接触判定のサンプル
"""
function app_13()
    rect1   = Rect([100, 100])
    rect1.x = [200, 200]
    rect2   = Rect([20, 50])
    while update!(g)
        rect2.x = g.system.mouse.x
        it = Intersects(rect2, rect1)
        if g.scene.timing[0.5]
            if it.top     print("top    ") end
            if it.bottom  print("bottom ") end
            if it.left    print("left   ") end
            if it.right   print("right  ") end
            if it.bounded print("bounded") end
            if it.bounds  print("bounds ") end
            println()
        end
        draw.([rect1, rect2])
        sleep(10/1000)
    end
end



function app_15()
    gr = Grid([32, 32], [20, 15])
    moji = Moji("Hello !")
    gr[3, 4] = moji
    while update!(g)
        draw(gr[2:5, 4:10])
    end
end




"""
線の接触判定
"""
function app_12()
    line1   = Line([100, 50])
    line1.x = [100, 100]
    line2   = Line([10, 70])
    while update!(g)
        line2.x = g.system.mouse.x
        it = Intersects(line1, line2)
        if it.cross println("cross") end
        draw(line1)
        draw(line2)
        sleep(10/1000)
    end
end







"""
# 各種図形等の表示
"""
function app_4()
    # Empty 
    nog = Empty()
    # Line
    line = Line()
    line.x = [100, 50]
    # Circle
    circle = Circle()
    circle.x = [50, 50]
    # Rect
    rect = Rect()
    rect.x = [400, 50]
    # Pattern
    pat = Pattern(kron([true true; false true], ones(Bool, 10, 10)))
    pat.x = [50, 50]
    # Moji
    hello = Moji("Hello World!")
    hello.bottomcenter = [400, 400] # 中央下が[400, 400]となるように配置
    # Image
    img1 = Image()
    img1.x = [50, 50]
    # scale!(img1)
    # Image を[12, 3]のグリッドで分割した画像 img2s::Matrix
    img2 = Image(SampleFiles().nge.sample1)
    scale!(img2, 0.1)
    img2s = cut(img2, [12, 3])
    img2s[8, 2].x = [200, 200]
    resize!(img2s[2, 2], [64, 64])

    while update!(g)
        # 背景色の設定
        draw(color = RGBA(1, 0, 0, 1)) 
        # 何もしない
        draw(nog)
        # 線の表示
        draw(line)
        # 円の表示
        draw(circle)
        # 長方形の表示
        draw(rect, is_filled = true)
        # パターンの表示
        draw(pat)
        # 文字の表示
        draw(hello)
        # 画像の表示
        draw(img1)
        # グリッドで切り取った行列の表示
        draw(img2s[8, 2])
    end
end






"""
# 画像表示のサンプル
クリックした場所に画像が残る。
"""
function app_1()
    # グリッドを作る
    gr  = Grid([32, 32], [20, 15])
    # 画像を読み出す(サイズを0.1倍)
    tree = Image(SampleFiles().nge.sample0)
    scale!(tree, 0.5)
    # 15個ランダムに画像を散らす
    n, m = size(gr)
    ipos = [gr[rand(1:n), rand(1:m)].bottomcenter for i = 1:15]
    # マウスで画像を設置する
    lpos = []
    while update!(g)
        # 背景色を白とする
        # マウスの位置がlower-middleになるときの描写用座標
        tree.bottomcenter = g.system.mouse.x
        if g.system.mouse.lbutton.down  
            push!(lpos, tree.bottomcenter)
        end
        draw(color = RGBA(1, 1, 1, 1))
        draw.(gr, color = RGBA(1, 0, 0, 1))
        draw(tree)
        (x -> (tree.bottomcenter = x; draw(tree))).(ipos)
        (x -> (tree.bottomcenter = x; draw(tree))).(lpos)
    end
end






"""
# ブロック崩し（終了判定などはなし）
"""
function app_5()
    # ボール
    ball   = (Donut(8, 4))
    ball.x = [320, 200]
    ball.v = [0, -300]
    ball.speed = norm(ball.v)

    # 操作オブジェクト
    paddle = (Rect([60, 10]))

    # ブロック（Grid）
    bricks = Grid([40, 20], [16, 5], offset = [0, 20])
    n, m = size(bricks)
    for i = 1:n for j = 1:m
        bricks[i, j] = (Rect([40, 20]))
        bricks[i, j].is_valid = true
    end end

    # 画面オブジェクト
    scene = (Rect(g.scene.w))
    
    while update!(g)
        # 座標の変更
        paddle.bottomcenter = [g.system.mouse.x[1], 400]
        ball.x  += ball.v * g.scene.dt
        
        # ブロックにぶつかったらブロックを消滅させ、跳ね返る
        n, m = size(bricks)
        for i = 1:n  for j = 1:m
            it_brick = Intersects(Circle(ball), bricks[i, j])
            if any(it_brick)
                if (! bricks[i, j].is_valid) continue end
                if     (it_brick.top & (ball.v[2] > 0)) | (it_brick.bottom & (ball.v[2] < 0))
                    ball.v[2] *= -1
                elseif (it_brick.left & (ball.v[1] > 0)) | (it_brick.right & (ball.v[1] < 0))
                    ball.v[1] *= -1
                end
                bricks[i, j].is_valid = false
                break
            end
        end end
        
        # 天井にぶつかったらはね返る
		if (ball.top < scene.top) & (ball.v[2] < 0)
            ball.v[2] *=-1
        end

        # 左右の壁にぶつかったらはね返る
        if    ((ball.left < scene.left) & (ball.v[1] < 0)) | ((ball.right > scene.right) & (ball.v[1] > 0))
            ball.v[1] *= -1
        end

		# パドルにあたったらはね返る
        it_paddle = Intersects(Rect(ball), paddle)
        if any(it_paddle) & (ball.v[2] > 0)
            ball.v = [(ball.x[1] - paddle.center[1]) * 10, - ball.v[2]]
            ball.v = ball.speed * ball.v / norm(ball.v)
        end

        # 描画
        (brick -> (brick.is_valid) ? draw(brick) : () -> ()).(bricks)
        draw(ball)
        draw(paddle)
    end
end



function app_16()
    circle = Circle()
    rect = Rect([100, 200])
    rect.x = [200, 200]
    while update!(g)
        circle.x = g.system.mouse.x
        it = Intersects(circle, rect)
        if any(it)
            str = "intersects "
            if it.top    str = str * "top    " end
            if it.bottom str = str * "bottom " end
            if it.left   str = str * "left   " end
            if it.right  str = str * "right  " end
            draw(str, [0, 0])
        end
        draw.([rect, circle])
    end
end



"""
文字を入力する(IMEからも可能)
"""
function app_17()
    ;
    while update!(g)
        draw(g.system.inputtext.text, [0, 0])
        draw("IME: "*g.system.inputtext.composition, [0, 100])
    end
end




using LinearAlgebra
"""
電卓
マクロを使っているので実行には注意が必要
(というか普通こんな実装すべきではないが…)
"""
function app_18()
    ret = ""
    register_key!(g, :RETURN)
    while update!(g)
        if g.system.keyboard.scans[:RETURN].down
            calctext = Meta.parse("$(g.system.inputtext.text)")
            try
                ret = string(eval(calctext))
            catch
                ret = ""
            end
            g.system.inputtext.text = ""
        end
        draw("calc  : $(g.system.inputtext.text)", [0, 0])
        draw("result: $ret", [0, 100])
    end
end




app_19_1() = begin
    rect   = Rect([100, 100])
    rect.x = [200, 100]
    while update!(g)
        draw("true", [0, 0])
        draw(rect)
    end
end
app_19_2() = begin
    rect   = Rect([100, 100])
    while update!(g)
        draw("false", [0, 0])
        draw(rect, [200, 100])
    end
end
"""
g.main = app_19
runapp(g, true)
"""
function app_19(flag = true)
    if flag app_19_1()
    else    app_19_2()
    end
end




g.main = app_18

runapp(g)



#=
# draw
rect   = Rect([100, 100])
rect.x = [200, 100]
draw(rect) # これが動作する

# draw
rect = Rect([100, 100])
draw(rect, [200, 100]) # rect.xの値を無視して動作するようにする

# app
g1, g2 = App(), App() # ２つのアプリを起動できるようにする

# message box
msg = MsgBox() # メッセージボックスの表示システム


# 音楽
mus1 = Audio(file) # Audio <: AbstractAudio
mus2 = LoopAudio(file)
play!(mus1)
play!(mus2) #10秒間続ける
stop!(mus2) # ループ再生を停止
=#


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


