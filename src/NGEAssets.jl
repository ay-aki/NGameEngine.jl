
using SimpleDirectMediaLayer


"""
# SampleFiles
デフォルトのアセットファイル群 \\
以下のようなファイルがあります。\\
```
samples = SampleFiles()
samples.nge.assets.ttf_files.NotoSansJP # font
samples.nge.assets.img_files.sample0
samples.nge.assets.img_files.sample1
samples.nge.assets.img_files.sample2
samples.sdl.assets.cat
samples.sdl.assets.fonts.BVSM
samples.sdl.assets.fonts.FiraCode
```
"""
struct SampleFiles
    sdl::NamedTuple
    nge::NamedTuple
    SampleFiles() = begin
        SDLDIR = pkgdir(SimpleDirectMediaLayer)
        NGEDIR = @__DIR__
        sdl = (
            assets = (
                cat = SDLDIR * "\\assets\\cat.png", 
                fonts = (
                    BVSM = SDLDIR * "\\assets\\fonts\\Bitstream-Vera-Sans-Mono\\VeraMono.ttf", 
                    FiraCode = SDLDIR * "\\assets\\fonts\\FiraCode\\ttf\\FiraCode-Light.ttf", 
                ), 
            ), 
        )
        nge = (
            assets = (
                ttf_files = (
                    NotoSansJP = NGEDIR * "\\..\\assets\\ttf_files\\Noto_Sans_JP\\NotoSansJP-VariableFont_wght.ttf", 
                ), 
                img_files = (
                    sample0 = NGEDIR * "\\..\\assets\\img_files\\sample0.png", 
                    sample1 = NGEDIR * "\\..\\assets\\img_files\\sample1.png", 
                    sample2 = NGEDIR * "\\..\\assets\\img_files\\sample2.png", 
                ), 
            ), 
        )
        return new(sdl, nge)
    end
end
export SampleFiles



