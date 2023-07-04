import PyPlot as plt


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
    
    plt.plot(data, fill(height, length(data)), "*")
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


# Define pure and equally tempered intervals
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

eq_temp_12 = 0:100:1200
eq_temp_53 = 0:(1200/53):1200
if length(eq_temp_53) == 53
    push!(eq_temp_53, 1200)
end
@assert(length(eq_temp_53) == 54)



# Define Western scales
# For sharp or flat, add or substract 1.
DO, RE, MI, FA, SOL, LA, SI, DO_2 = [1, 3, 5, 6, 8, 10, 12, 13]

western_scales = Dict(
    "ionian" => [DO, RE, MI, FA, SOL, LA, SI, DO_2]
)

d = western_scales
western_scales = Dict()
for scale in keys(d)
    western_scales[scale] = map(i -> eq_temp_12[i], d[scale])
end

# Define Turkish scales
DO, RE, MI, FA, SOL, LA, SI, DO_2 = [1, 10, 19, 23, 32, 41, 50, 54]

turkish_scales = Dict(
    "cagah" => [DO, RE, MI, FA, SOL]
)

d = turkish_scales
turkish_scales = Dict()
for scale in keys(d)
    turkish_scales[scale] = map(i -> eq_temp_53[i], d[scale])
end


# Plot scales wrt intervals
plt.figure()
plot_dots_at_height(harmonics, 6, "Harmonics")
plot_dots_at_height(eq_temp_12, 5, "Equal temp. 12")
plot_dots_at_height(eq_temp_53, 4, "Equal temp. 53")
plot_dots_at_height(western_scales["ionian"], 3, "Ionian")
plot_dots_at_height(turkish_scales["cagah"], 2, "Cagah")
plt.vlines(collect(values(harmonics)), 0, 6)

plt.yticks(y_label_locations, y_labels)
plt.xlabel("cents")

plt.show()


