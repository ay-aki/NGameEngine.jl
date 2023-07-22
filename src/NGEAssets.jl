
using SimpleDirectMediaLayer


"""
# SampleFiles
デフォルトのアセットファイル群 \\
以下のようなファイルがあります。\\
```
samples = SampleFiles()
samples.sdl.cat
samples.sdl.BVSM
samples.sdl.FiraCode
samples.nge.NotoSansJP # font
samples.nge.NotoEmoji
samples.nge.sample0
samples.nge.sample1
samples.nge.sample2
samples.nge.mp3_sample0
samples.nge.mp3_sample1
```
"""
struct SampleFiles sdl; nge end
export SampleFiles
function SampleFiles()
    SDLDIR = pkgdir(SimpleDirectMediaLayer)
    NGEDIR = @__DIR__
    sdl = (
        cat = SDLDIR * "\\assets\\cat.png", 
        BVSM = SDLDIR * "\\assets\\fonts\\Bitstream-Vera-Sans-Mono\\VeraMono.ttf", 
        FiraCode = SDLDIR * "\\assets\\fonts\\FiraCode\\ttf\\FiraCode-Light.ttf", 
    )
    nge = (
        NotoSansJP = NGEDIR * "\\..\\assets\\ttf_files\\Noto_Sans_JP\\NotoSansJP-VariableFont_wght.ttf", 
        NotoEmoji = NGEDIR * "\\..\\assets\\ttf_files\\Noto_Emoji\\NotoEmoji-VariableFont_wght.ttf", 
        sample0 = NGEDIR * "\\..\\assets\\img_files\\jisaku\\sample0.png", 
        sample1 = NGEDIR * "\\..\\assets\\img_files\\jisaku\\sample1.png", 
        sample2 = NGEDIR * "\\..\\assets\\img_files\\jisaku\\sample2.png", 
        mp3_sample0 = NGEDIR * "\\..\\assets\\audio_files\\otologic\\Loop01.mp3", 
        mp3_sample1 = NGEDIR * "\\..\\assets\\audio_files\\otologic\\Onoma-Inspiration11-1(Low).mp3", 
    )
    
    return SampleFiles(sdl, nge)
end

