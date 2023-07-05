import PyPlot as plt
import OrderedCollections: OrderedDict as Dict


n_harmonics = 31 # 31


to_cents(ratio) = 1200 * log2(ratio)
to_ratio(cents) = 2 ^ (cents / 1200)

function plot_dots_at_height(d::Dict, height::Real, label::AbstractString)
    k = sort(collect(keys(d)))
    v = map(k -> d[k], k)
    plot_dots_at_height(k, v, height, label)
end

function plot_dots_at_height(data::AbstractVector, height::Real, label::AbstractString)
    plot_dots_at_height(string.(1:length(data)), data, height, label)
end

y_label_locations = []
y_labels = []
function plot_dots_at_height(annotations::AbstractVector, data::AbstractVector, height::Real, label::AbstractString)
    global y_label_locations
    global y_labels

    push!(y_label_locations, height)
    push!(y_labels, label)
    
    plt.plot(data, fill(height, length(data)), "*", markersize=8)
    for i = 1:length(data)
        plt.annotate(annotations[i], (data[i], height))
    end
end

function to_dict(v::AbstractVector)
    d = Dict()
    for i = 1:length(v)
        d[i] = v[i]
    end
    return d
end

scale_to_cents(scale::AbstractVector, temperament_map::AbstractVector) =
    map(i -> temperament_map[i], scale)

function scale_to_cents(scales::AbstractDict, temperament_map::AbstractVector)
    d = Dict()
    for name in keys(scales)
        d[name] = scale_to_cents(scales[name], temperament_map)
    end
    return d
end

function transpose_to_DO!(v::AbstractVector, temperament::Integer)
    if length(v) > 0
        n = v[1] - 1
        for i = 1:length(v)
            v[i] -= n
            if v[i] <= 0
                v[i] += temperament
            end
        end
    end
end

# Define pure intervals
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


# Define possible fundamental frequencies for the reference note.
fundamentals = copy(harmonics)
delete!(fundamentals, 1)
delete!(fundamentals, 2)
for k in keys(fundamentals)
    fundamentals[k] = 1200 - fundamentals[k]
end


# Define equally tempered intervals
eq_temp_12 = 0:100:1200
eq_temp_53 = 0:(1200/53):1200
if length(eq_temp_53) == 53
    push!(eq_temp_53, 1200)
end
@assert(length(eq_temp_53) == 54)

western_notes_names = ["do", "", "re", "", "mi", "fa", "", "sol", "", "la", "", "si", "do"]
western_notes = eq_temp_12

turkish_classical_note_names =
    ["do", "", "", "", "re", "", "", "", "mi", "fa", "", "", "", "", "sol", "", "", "", "la", "", "", "", "si", "", "do"]
turkish_classical_notes =
    map(x -> eq_temp_53[x+1], [0 , 4 , 5 , 8 ,  9 , 13, 14, 17, 18, 22, 23, 26, 27, 30, 31, 35, 36, 39, 40, 44, 45, 48, 49, 52, 53])



# Define Western scales
# For sharp or flat, add or substract 1.
DO, RE, MI, FA, SOL, LA, SI, DO_2 = [1, 3, 5, 6, 8, 10, 12, 13]

western_scales = Dict(
    "Ionian (I)"     => [DO  , RE  , MI  , FA  , SOL  , LA  , SI  , DO_2],
    "Dorian (II)"    => [DO  , RE  , MI-1, FA  , SOL  , LA  , SI-1, DO_2],
    "Phrygian (III)" => [DO  , RE-1, MI-1, FA  , SOL  , LA-1, SI-1, DO_2],
    "Lydian (IV)"    => [DO  , RE  , MI  , FA+1, SOL  , LA  , SI  , DO_2],
    "Mixolydian (V)" => [DO  , RE  , MI  , FA  , SOL  , LA  , SI-1, DO_2],
    "Aeolian (VI)"   => [DO  , RE  , MI-1, FA  , SOL  , LA-1, SI-1, DO_2],
    "Locrian (VII)"  => [DO  , RE-1, MI-1, FA  , SOL-1, LA-1, SI-1, DO_2]
)


# Define Turkish scales
DO, RE, MI, FA, SOL, LA, SI, DO_2 = [1, 10, 19, 23, 32, 41, 50, 54]

# Tetrachords (dörtlüler) and pentachords (beşliler)
turkish_classical_scalets = Dict(
    "Çagah dörtlüsü"   => [DO  , RE  , MI  , FA],
    "Çagah beşlisi"    => [DO  , RE  , MI  , FA  , SOL],
    "Buselik dörtlüsü" => [DO  , RE  , MI-5, FA],
    "Buselik beşlisi"  => [DO  , RE  , MI-5, FA  , SOL],
    "Kürdi dörtlüsü"   => [DO  , RE-5, MI-5, FA],
    "Kürdi beşlisi"    => [DO  , RE-5, MI-5, FA  , SOL],
    "Rast dörtlüsü"    => [DO  , RE  , MI-1, FA],
    "Rast beşlisi"     => [DO  , RE  , MI-1, FA  , SOL],
    "Hicaz dörtlüsü"   => [DO  , RE-4, MI-1, FA],
    "Hicaz beşlisi"    => [DO  , RE-4, MI-1, FA  , SOL],
    "Uşşak dörtlüsü"   => [DO  , RE-1, MI-5, FA],
    "Hüseyni beşlisi"  => [DO  , RE-1, MI-5, FA  , SOL],
    "Segah dörtlüsü"   => [DO  , RE-4, MI-4, FA],
    "Segah beşlisi"    => [DO  , RE-4, MI-4, FA  , SOL],
    "Saba dörtlüsü"    => [DO  , RE-1, MI-5, FA-4],
    "Nikriz beşlisi"   => [DO  , RE  , MI-4, FA+4, SOL],
    "Hüzzam beşlisi"   => [DO  , RE-4, MI-4, FA-3, SOL]
)

# kaynak: http://adanamusikidernegi.com/?pnum=289&pt=Makamlar
turkish_classical_scales = Dict(
    # basit makamlar
    "Çargah / mahur (sol) / acemaşiran (fa) makamı" => [DO, RE, MI, FA, SOL, LA, SI], # durak: do, güçlü: sol, yeden: si
    "Buselik / şehnaz buselik / nihavent (sol) / ruhnevaz (mi) / sultaniyegâh (re) makamı" => [LA, SI, DO, RE, MI, FA, SOL], # durak: la, güçlü: mi, yeden: sol+4
    "Kürdî / kürdilihicazkâr (sol) / aşk’efzâ (mi) / ferahnümâ (re) makamı" => [LA, SI-5, DO, RE, MI, FA, SOL], # durak: la, güçlü: re, yeden: sol
    "Rast makamı"            => [SOL, LA, SI-1, DO, RE, MI, FA+4], # durak: sol, güçlü: re, yeden: fa+4
    "Uşşak / bayati makamı"  => [LA, SI-1, DO, RE, MI, FA, SOL], # durak: la, güçlü: re, yeden: sol
    "Neva / tahir makamı"    => [LA, SI-1, DO, RE, MI, FA+4, SOL], # durak: la, güçlü: re, yeden: sol
    "Hümayun makamı"         => [LA, SI-4, DO+4, RE, MI, FA, SOL], # durak: la, güçlü: re, yeden: sol
    "Hicaz makamı"           => [LA, SI-4, DO+4, RE, MI, FA+4, SOL], # durak: la, güçlü: re, yeden: sol
    "Uzzal makamı"           => [LA, SI-4, DO+4, RE, MI, FA+4, SOL], # durak: la, güçlü: mi, yeden: sol
    "Zirgüleli hicaz / zirgüleli suzinâk (sol) / Hicazkâr (sol) / evcârâ (fa#) / suz-i dil (mi) / şedd-i araban (re) makamı" => [LA, SI-4, DO+4, RE, MI, FA+1, SOL+4], # durak: la, güçlü: mi, yeden: sol+4
    "Hüseyni / muhayyer makamı" => [LA, SI-1, DO, RE, MI, FA+4, SOL], # durak: la, güçlü: mi, yeden: sol
    "Karcığar makamı"           => [LA, SI-1, DO, RE, MI-4, FA+4, SOL], # durak: la, güçlü: re, yeden: sol
    "Basit suzinak makamı"      => [SOL, LA, SI-1, DO, RE, MI-4, FA+4], # durak: sol, güçlü: re, yeden: fa+4
    
    "Isfahân makamı"          => [],
    "Gülizâr makamı"          => [],
    "Segah / heft-gâh (reb) makamı" => [SOL, LA, SI-1, DO, RE, MI-1, FA+4],
    "Neveser / reng-i dil (fa) makamı" => [],
)


# Transpose all scales to DO.
map(values(turkish_classical_scales)) do s
    transpose_to_DO!(s, 53)
end


western_scales = scale_to_cents(western_scales, eq_temp_12)
turkish_classical_scalets = scale_to_cents(turkish_classical_scalets, eq_temp_53)
turkish_classical_scales = scale_to_cents(turkish_classical_scales, eq_temp_53)



# Plot scales wrt intervals
plt.figure()
height = 0
plot_dots_at_height(harmonics, height, "Harmonics")
plot_dots_at_height(fundamentals, height -= 0.5, "Fundamentals")
plot_dots_at_height(eq_temp_12, height -= 0.5, "Equal temp. 12")
plot_dots_at_height(western_notes_names,
                    western_notes, height -= 0.5, "Wetern Music Notes")
plot_dots_at_height(eq_temp_53, height -= 0.5, "Equal temp. 53")
plot_dots_at_height(turkish_classical_note_names,
                    turkish_classical_notes, height -= 0.5, "Turkish Classical Music Notes")

height -= 0.5
function plot_scales(scales)
    global height
    for name in keys(scales)
        plot_dots_at_height(scales[name], height -= 0.5, name)
    end
end

plot_scales(western_scales)
#height -= 0.5
#plot_scales(turkish_classical_scalets)
height -= 0.5
plot_scales(turkish_classical_scales)

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
    plt.vlines(harmonics[k], height, 0, alpha=alpha)
    if k > 2
        plt.vlines(fundamentals[k], height, 0, alpha=alpha, color="orange")
    end
end


plt.yticks(y_label_locations, y_labels)
plt.xlabel("cents")
plt.tight_layout()
plt.show()


