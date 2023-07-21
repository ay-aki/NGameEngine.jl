# NGameEngine（NGE）

SDL2(SimpleDirectMediaLayer) Wrapper for julia

# 注意

NGEのサンプルのassetを用いてアプリを制作し配布する場合は、LICENSEを確認してください。
特に、assets/otologicフォルダ内部に配置されているサンプルファイルを用いる場合、全てが以下の著作権表記を必要とします。

> BGM by OtoLogic(CC BY 4.0)

# NGEの目的

NGEの機能はSDL2のラッパーとして動作するJuliaのゲームエンジンです。
Juliaの文法を生かし、SDL2をベースとした2dゲームの作成が簡易にプログラマチックに行えるエンジンとして開発しています。

最終的には、疑似コードレベルの短くて分かりやすいコードで動かせるレベルで、覚えやすい機能を提供することが目的となります。

# NGEの機能

- NGEによって空のSDLアプリケーションを起動するには、以下のコードを実行してください。真っ黒の画面が表示され、右上の×を押すとウインドウが消えます。

```julia
using NGE

g = App()

function app_0()
    ;
    while update!(g)
        ;
    end
end

g.main = app_0

runapp(g)
```

- キーボード、マウス入力は以下のようなコードで実行できます。

```julia
using NGE

g = App()

# 入力を受け取るキーを設定
register_keys!(g, [:w, :s, :a, :d])

function app_1()
    n = 0
    while update!(g)
        # クリックされたときマウス座標を表示する
        if g.system.mouse.lbutton.down  println(g.system.mouse.x)
        end
        # キーボードの[W]が押されたとき、nを-1する
        if g.system.keyboard.scans[:w].down   n -= 1
        end
        # マウスのホイールがいずれかの方向に多少でも動いた場合、nを+1する。
        if g.system.mouse.wheel.dx .> [0, 0]  n += 1
        end
        sleep(0.01)
    end
end

g.main = app_1

runapp(g)
```

- 各種図形の表示は以下の要領で行えます。

```julia
using NGE

g = App()

function app_2()
    line    = Line(vector = [30, 50]) # 線
    circle  = Circle(r = 20) # 円
    donut   = Circle(r = 20, r0 = 10) # ドーナツ型
    ellipse = Circle(r = [50, 60]) # 楕円
    rect    = Rectangle(w = [40, 20])
    pat     = Tf(a = 10) * Pattern(X = [true false; true true])
    while update!(g)
        draw(line, [10, 10])
        draw(circle, [100, 50])
        draw(donut, [100, 100])
        draw(ellipse, [100, 150])
        draw(rect, [200, 50])
        draw(pat, [200, 50])
        sleep(0.01)
    end
end

g.main = app_2

runapp(g)
```



- 


