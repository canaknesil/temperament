import PyPlot as plt
import OrderedCollections: OrderedDict as Dict
import Base: convert, +, -

#
# Parameters
#
n_harmonics = 31 # 31


#
# Tone Type
#
eq_temp_12 = 0:100:1200
eq_temp_53 = 0:(1200/53):1200
if length(eq_temp_53) == 53
    push!(eq_temp_53, 1200)
end
@assert(length(eq_temp_53) == 54)

eq_temp_12 = eq_temp_12[1:end-1]
eq_temp_53 = eq_temp_53[1:end-1]

abstract type Tone end
struct EquallyTempered{N} <: Tone
    i::Integer
end
const ET_12 = EquallyTempered{12}
const ET_53 = EquallyTempered{53}

convert(::Type{EquallyTempered{N}}, i::Integer) where N = EquallyTempered{N}(i)
+(a::EquallyTempered{N}, b::Integer) where N = EquallyTempered{N}(a.i + b)
+(a::Integer, b::EquallyTempered{N}) where N = EquallyTempered{N}(a + b.i)
-(a::EquallyTempered{N}, b::Integer) where N = EquallyTempered{N}(a.i - b)
-(a::Integer, b::EquallyTempered{N}) where N = EquallyTempered{N}(a - b.i)
-(a::EquallyTempered{N}, b::EquallyTempered{N}) where N = a.i - b.i

temperament_map(::Type{ET_12}) = eq_temp_12
temperament_map(::Type{ET_53}) = eq_temp_53
temperament_map(t::Tone) = temperament_map(typeof(t))


#
# Scale Type
#
abstract type Scale end

mutable struct WesternScale <: Scale
    name::AbstractString
    scale::AbstractVector{ET_12}
end

# dörtlü veya beşliler, nadiren üçlü
mutable struct TurkishSequence <: Scale
    name::AbstractString
    scale::AbstractVector{ET_53}
end

abstract type TurkishScale <: Scale end

@enum MelodicDevelopment increasing_scale decreasing_scale increasing_and_decreasing_scale

mutable struct SimpleTurkishScale <: TurkishScale
    name::AbstractString
    sequence_1::TurkishSequence
    sequence_2::TurkishSequence
    scale::AbstractVector{ET_53}
    tonic::ET_53    # durak
    dominant::ET_53 # güçlü
    leading::ET_53  # leading tone, yeden 
    development::Union{MelodicDevelopment, Missing} # seyir
end
function SimpleTurkishScale(;name, sequence_1, sequence_2, tonic, dominant, leading, development)
    scale_1 = transpose(sequence_1.scale, tonic)
    scale_2 = transpose(sequence_2.scale, scale_1[end])
    scale = vcat(scale_1, scale_2[2:end])
    return SimpleTurkishScale(name, sequence_1, sequence_2, scale, tonic, dominant, leading, development)
end

get_tonic(scale::Union{WesternScale, TurkishSequence}) = scale.scale[1]
get_tonic(scale::TurkishScale) = scale.tonic
get_name(scale::Scale) = scale.name
get_scale(scale::Scale) = scale.scale

temperament_type(scale::WesternScale) = ET_12
temperament_type(scale::TurkishSequence) = ET_53
temperament_type(scale::TurkishScale) = ET_53


#
# Utility functions for defined types
#
to_cents(ratio::Real) = 1200 * log2(ratio)
to_ratio(cents::Real) = 2 ^ (cents / 1200)

function to_cents(tone::Tone)
    m = temperament_map(tone)
    return m[mod(tone.i - 1, length(m)) + 1]
end

function transpose(scale::AbstractVector{T}, tonic::T) where T <: Tone
    scale = deepcopy(scale)
    d = tonic - scale[1]
    scale .+= d
    return scale
end


#
# Plotting functions
#
function plot_dots_at_height(d::Dict, args...; kwargs...)
    k = sort(collect(keys(d)))
    v = map(k -> d[k], k)
    plot_dots_at_height(v, args...; annotations = string.(k), kwargs...)
end

y_label_locations = []
y_labels = []
function plot_dots_at_height(data::AbstractVector, height::Real, label::AbstractString; annotations::AbstractVector{<:AbstractString} = String[], annotation_rotation = 0)
    global y_label_locations
    global y_labels

    push!(y_label_locations, height)
    push!(y_labels, label)
    
    plt.plot(data, fill(height, length(data)), "*", markersize=8)
    if !isempty(annotations)
        for i = 1:length(data)
            plt.annotate(annotations[i], (data[i], height), rotation=annotation_rotation)
        end
    end
end


#
# Utility functions
#
function to_dict(v::AbstractVector)
    d = Dict()
    for i = 1:length(v)
        d[i] = v[i]
    end
    return d
end

function to_dict(v::AbstractVector{S}) where S <: Scale
    d = Dict{AbstractString}{S}()
    for scale in v
        d[get_name(scale)] = scale
    end
    return d
end



#
# Define "harmonics" w.r.t. the reference, mapped onto one octave. nth harmonic => frequency ratio in cents
#
harmonics = to_dict(1:n_harmonics)
# remove notes that will be mapped to the same point after shirinking to one octave
for k in keys(harmonics)
    if k>2 && iseven(k)
        delete!(harmonics, k)
    end
end
# map to single octave
for k in keys(harmonics)
    h = k
    while h > 2
        h /= 2
    end
    harmonics[k] = to_cents(h)
end


#
# Define "fundamentals" w.r.t. the reference, where the reference would be the nth harmonic, mapped onto one octave.
# n => frequency ratio in cents
# "harmonics" and "fundamentals" together show just intervals w.r.t. a reference.
#
fundamentals = copy(harmonics)
delete!(fundamentals, 1)
delete!(fundamentals, 2)
for k in keys(fundamentals)
    fundamentals[k] = 1200 - fundamentals[k]
end


#
# Define Tones
#
western_note_names = ["do", "do♯ / re♭", "re", "re♯ / mi♭", "mi", "fa", "fa♯ / sol♭", "sol", "sol♯ / la♭", "la", "la♯ / si♭", "si"]
western_notes = ET_12.(1:12)

turkish_note_names =
    ["do", "", "", "", "", "re", "", "", "", "", "mi", "", "", "fa", "", "", "", "", "sol", "", "", "", "", "la", "", "", "", "", "si", "", ""]
turkish_notes =
    ET_53.(1 .+ [0, 1, 4, 5, 8, 9, 10, 13, 14, 17, 18, 19, 21, 22, 23, 26, 27, 30, 31, 32, 35, 36, 39, 40, 41, 44, 45, 48, 49, 50, 52])


#
# Define Western scales
# For sharp or flat, add or substract 1.
#
DO, RE, MI, FA, SOL, LA, SI = ET_12[1, 3, 5, 6, 8, 10, 12]

western_scales = Scale[
    WesternScale("Major"         , [DO  , RE  , MI  , FA  , SOL  , LA  , SI  ]), # Ionian (I)
    WesternScale("Dorian (II)"   , [DO  , RE  , MI-1, FA  , SOL  , LA  , SI-1]),
    WesternScale("Phrygian (III)", [DO  , RE-1, MI-1, FA  , SOL  , LA-1, SI-1]),
    WesternScale("Lydian (IV)"   , [DO  , RE  , MI  , FA+1, SOL  , LA  , SI  ]),
    WesternScale("Mixolydian (V)", [DO  , RE  , MI  , FA  , SOL  , LA  , SI-1]),
    WesternScale("Minor"         , [DO  , RE  , MI-1, FA  , SOL  , LA-1, SI-1]), # Aeolian (VI)
    WesternScale("Locrian (VII)" , [DO  , RE-1, MI-1, FA  , SOL-1, LA-1, SI-1])
]


#
# Define Turkish scales
#
DO, RE, MI, FA, SOL, LA, SI = ET_53[1, 10, 19, 23, 32, 41, 50]

# Tetrachords (dörtlüler) and pentachords (beşliler)
turkish_sequences = Scale[
    TurkishSequence("Çargah dörtlüsü" , [DO  , RE  , MI  , FA]),
    TurkishSequence("Çargah beşlisi"  , [DO  , RE  , MI  , FA  , SOL]),
    TurkishSequence("Buselik dörtlüsü", [DO  , RE  , MI-5, FA]),
    TurkishSequence("Buselik beşlisi" , [DO  , RE  , MI-5, FA  , SOL]),
    TurkishSequence("Kürdi dörtlüsü"  , [DO  , RE-5, MI-5, FA]),
    TurkishSequence("Kürdi beşlisi"   , [DO  , RE-5, MI-5, FA  , SOL]),
    TurkishSequence("Rast dörtlüsü"   , [DO  , RE  , MI-1, FA]),
    TurkishSequence("Rast beşlisi"    , [DO  , RE  , MI-1, FA  , SOL]),
    TurkishSequence("Hicaz dörtlüsü"  , [DO  , RE-4, MI-1, FA]),
    TurkishSequence("Hicaz beşlisi"   , [DO  , RE-4, MI-1, FA  , SOL]),
    TurkishSequence("Uşşak dörtlüsü"  , [DO  , RE-1, MI-5, FA]),
    TurkishSequence("Hüseyni beşlisi" , [DO  , RE-1, MI-5, FA  , SOL]),
    TurkishSequence("Segah dörtlüsü"  , [DO  , RE-4, MI-4, FA]),
    TurkishSequence("Segah beşlisi"   , [DO  , RE-4, MI-4, FA  , SOL]),
    TurkishSequence("Saba dörtlüsü"   , [DO  , RE-1, MI-5, FA-4]),
    TurkishSequence("Nikriz beşlisi"  , [DO  , RE  , MI-4, FA+4, SOL]),
    TurkishSequence("Hüzzam beşlisi"  , [DO  , RE-4, MI-4, FA-3, SOL])
]
seq = turkish_sequences = to_dict(turkish_sequences)

# kaynak: http://adanamusikidernegi.com/?pnum=289&pt=Makamlar
turkish_scales = Scale[
    SimpleTurkishScale(
        name = "Çargah",
        sequence_1 = seq["Çargah beşlisi"],
        sequence_2 = seq["Çargah dörtlüsü"],
        tonic = DO,
        dominant = SOL,
        leading = SI,
        development = missing
    ),
    SimpleTurkishScale(
        name = "Buselik",
        sequence_1 = seq["Buselik beşlisi"],
        sequence_2 = seq["Kürdi dörtlüsü"],
        tonic = LA,
        dominant = MI,
        leading = SOL+4,
        development = missing
    ),
]
turkish_scales = to_dict(turkish_scales)

#     "Çargah / mahur (sol) / acemaşiran (fa) makamı" => [DO, RE, MI, FA, SOL, LA, SI], # durak: do, güçlü: sol, yeden: si
#     "Buselik / şehnaz buselik / nihavent (sol) / ruhnevaz (mi) / sultaniyegâh (re) makamı" => [LA, SI, DO, RE, MI, FA, SOL], # durak: la, güçlü: mi, yeden: sol+4
#     "Kürdî / kürdilihicazkâr (sol) / aşk’efzâ (mi) / ferahnümâ (re) makamı" => [LA, SI-5, DO, RE, MI, FA, SOL], # durak: la, güçlü: re, yeden: sol
#     "Rast makamı"            => [SOL, LA, SI-1, DO, RE, MI, FA+4], # durak: sol, güçlü: re, yeden: fa+4
#     "Uşşak / bayati makamı"  => [LA, SI-1, DO, RE, MI, FA, SOL], # durak: la, güçlü: re, yeden: sol
#     "Neva / tahir makamı"    => [LA, SI-1, DO, RE, MI, FA+4, SOL], # durak: la, güçlü: re, yeden: sol
#     "Hümayun makamı"         => [LA, SI-4, DO+4, RE, MI, FA, SOL], # durak: la, güçlü: re, yeden: sol
#     "Hicaz makamı"           => [LA, SI-4, DO+4, RE, MI, FA+4, SOL], # durak: la, güçlü: re, yeden: sol
#     "Uzzal makamı"           => [LA, SI-4, DO+4, RE, MI, FA+4, SOL], # durak: la, güçlü: mi, yeden: sol
#     "Zirgüleli hicaz / zirgüleli suzinâk (sol) / Hicazkâr (sol) / evcârâ (fa#) / suz-i dil (mi) / şedd-i araban (re) makamı" => [LA, SI-4, DO+4, RE, MI, FA+1, SOL+4], # durak: la, güçlü: mi, yeden: sol+4
#     "Hüseyni / muhayyer makamı" => [LA, SI-1, DO, RE, MI, FA+4, SOL], # durak: la, güçlü: mi, yeden: sol
#     "Karcığar makamı"           => [LA, SI-1, DO, RE, MI-4, FA+4, SOL], # durak: la, güçlü: re, yeden: sol
#     "Basit suzinak makamı"      => [SOL, LA, SI-1, DO, RE, MI-4, FA+4], # durak: sol, güçlü: re, yeden: fa+4
    
#     "Isfahân makamı"          => [],
#     "Gülizâr makamı"          => [],
#     "Segah / heft-gâh (reb) makamı" => [SOL, LA, SI-1, DO, RE, MI-1, FA+4],
#     "Neveser / reng-i dil (fa) makamı" => [],




# Plot scales wrt intervals
plt.figure(figsize=[16, 8]) # default figsize: [6.4, 4.8]
height = 0
plot_dots_at_height(harmonics, height, "Harmonics")
plot_dots_at_height(fundamentals, height -= 0.5, "Fundamentals")
#plot_dots_at_height(temperament_map(ET_12), height -= 0.5, "12-Tone Equal Temperament")
plot_dots_at_height(to_cents.(western_notes), height -= 0.5, "Wetern Music Notes (12-ET)", annotations = western_note_names, annotation_rotation=45)
plot_dots_at_height(temperament_map(ET_53), height -= 0.5, "53-Tone Equal Temperament")
plot_dots_at_height(to_cents.(turkish_notes), height -= 0.5, "Turkish Music Notes", annotations = turkish_note_names, annotation_rotation=45)

height -= 0.5
function plot(scale::Scale)
    global height
    new_tonic = temperament_type(scale)(1)
    plot_dots_at_height(to_cents.(transpose(get_scale(scale), new_tonic)), height -= 0.5, get_name(scale),
                        annotations = string.(1:length(get_scale(scale))))
end

plot(western_scales[1])
plot(western_scales[6])
height -= 0.5
plot.(values(turkish_sequences))
height -= 0.5
plot.(values(turkish_scales))

bottom, top = plt.ylim()

#plt.vlines(collect(values(harmonics)), height, 0, alpha=0.5)
#plt.vlines(collect(values(fundamentals)), height, 0, color="orange", alpha=0.5)

# after nth harmonic, fade the lines
n = 3
for k in keys(harmonics)
    if k >= n
        alpha = 1 / (k - n + 1)
    else
        alpha = 1
    end
    alpha = sqrt(alpha) # slow down the fading
    plt.vlines(harmonics[k], bottom, top, alpha=alpha, zorder=-1)
    if k > 2
        plt.vlines(fundamentals[k], bottom, top, alpha=alpha, color="orange", zorder=-1)
    end
end


plt.yticks(y_label_locations, y_labels)
plt.xlabel("cents")
plt.tight_layout()
plt.savefig("plots/all.pdf")

#plt.show()


