module NGE

include("./NGESDL.jl")
using .NGESDL
using Colors, LinearAlgebra
export norm, kron

include("./NGEUtils.jl")


global section, win, renderer, event_ref, events, t0, t_old

global reserve_close
reserve_close = [] # close all

global reserve_destroy
reserve_destroy = [] # destroy all

global global_list_font_loaded
global_list_font_loaded = []

include("./NGEAssets.jl")

global samplefiles
samplefiles = SampleFiles()

global list_font_loaded, list_image_loaded, list_audio_loaded
list_font_loaded  = []
list_image_loaded = []
list_audio_loaded = []

include("./NGEApp.jl")

include("./NGEObject.jl")
include("./NGEObjectUtils.jl")
include("./NGEIntersects.jl")


end # module NGE
