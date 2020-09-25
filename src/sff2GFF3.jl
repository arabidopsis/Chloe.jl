module Sff2Gff
export writeallGFF3

import ..Annotator: getFeatureType, Feature, readFeatures, groupFeaturesIntoGeneModels

struct ModelArray
    genome_id::String
    genome_length::Int32
    strand::Char
    features::Vector{Feature}
end
function mergeAdjacentFeaturesinModel!(model::Vector{Feature}, genome_id, genome_length, strand)
    f1_index = 1
    f2_index = 2
    while f2_index <= length(model)
        f1 = model[f1_index]
        f2 = model[f2_index]
        # if adjacent features are same type, merge them into a single feature
        if getFeatureType(f1) == getFeatureType(f2)
            @debug "[$(genome_id)]$(strand) merging $(f1.path) and $(f2.path)"
            f1.length += f2.length
            deleteat!(model, f2_index)
        else
            f1_index += 1
            f2_index += 1
        end
    end
    return ModelArray(genome_id, genome_length, strand, model)
end

function writeGFF3(outfile, genemodel::ModelArray)
    features = genemodel.features
    path_components = split(first(features).path, '/')
    id = path_components[1]
    if parse(Int, path_components[2]) > 1
        id = id * "-" * path_components[2]
    end
    parent = id
    start = first(features).start
    finish = last(features).start + last(features).length - 1
    length = finish - start + 1
    if genemodel.strand == '-'
        start = genemodel.genome_length - finish + 1
        if start < 1
            start += genemodel.genome_length
        end
        finish = start + length - 1
    end
    # gene
    write(outfile, join([genemodel.genome_id,"Chloe","gene",start,finish], "\t"))
    write(outfile, "\t", ".", "\t", genemodel.strand, "\t", ".", "\t", "ID=", id, ";Name=", path_components[1], "\n")
    # RNA product
    ft = getFeatureType(first(features))
    if ft == "CDS"
        write(outfile, join([genemodel.genome_id,"Chloe","mRNA",start,finish], "\t"))
        parent = id * ".mRNA"
        write(outfile, "\t", ".", "\t", genemodel.strand, "\t", ".", "\t", "ID=", parent, ";Parent=", id, "\n")
    elseif ft == "rRNA"
        write(outfile, join([genemodel.genome_id,"Chloe","rRNA",start,finish], "\t"))
        parent = id * ".rRNA"
        write(outfile, "\t", ".", "\t", genemodel.strand, "\t", ".", "\t", "ID=", parent, ";Parent=", id, "\n")
    elseif ft == "tRNA"
        write(outfile, join([genemodel.genome_id,"Chloe","tRNA",start,finish], "\t"))
        parent = id * ".tRNA"
        write(outfile, "\t", ".", "\t", genemodel.strand, "\t", ".", "\t", "ID=", parent, ";Parent=", id, "\n")
    end
    if genemodel.strand == '+'
        for feature in features
            type = getFeatureType(feature)
            if type == "tRNA" || type == "rRNA"
                type = "exon"
            end
            start = feature.start
            finish = feature.start + feature.length - 1
            length = finish - start + 1
            phase = type == "CDS" ? string(feature.phase) : "."
            write(outfile, join([genemodel.genome_id,"Chloe",type,start,finish], "\t"))
            write(outfile, "\t", ".", "\t", genemodel.strand, "\t", phase, "\t", "ID=", feature.path, ";Parent=", parent, "\n")
        end
    else
        for feature in Iterators.reverse(features)
            type = getFeatureType(feature)
            if type == "tRNA" || type == "rRNA"
                type = "exon"
            end
            start = feature.start
            finish = feature.start + feature.length - 1
            length = finish - start + 1
            start = genemodel.genome_length - finish + 1
            if start < 1
                start += genemodel.genome_length
            end
            finish = start + length - 1
            phase = type == "CDS" ? string(feature.phase) : "."
            write(outfile, join([genemodel.genome_id,"Chloe",type,start,finish], "\t"))
            write(outfile, "\t", ".", "\t", genemodel.strand, "\t", phase, "\t", "ID=", feature.path, ";Parent=", parent, "\n")
        end
    end
    write(outfile, "###\n")
end
function writeallGFF3(;sff_files=String[], directory=nothing)
    
    function add_models!(models_as_feature_arrays, features, strand)
        # afeatures = collect(features.interval_tree, Vector{Feature}())
        afeatures =  Vector{Feature}()
        for feature in features.interval_tree
            push!(afeatures, feature)
        end
        sort!(afeatures, by=f -> f.path)
        models = groupFeaturesIntoGeneModels(afeatures)
        for model in models
            if isempty(model)
                continue
            end
            push!(models_as_feature_arrays, mergeAdjacentFeaturesinModel!(model, features.genome_id, features.genome_length, strand))
        end
    end
    
    for infile in sff_files
        fstrand_features, rstrand_features = readFeatures(infile)
        models_as_feature_arrays = Vector{ModelArray}()
        # for each strand
        # group into gene models
        add_models!(models_as_feature_arrays, fstrand_features, '+')
        add_models!(models_as_feature_arrays, rstrand_features, '-')

        # interleave gene models from both strands
        sort!(models_as_feature_arrays, by=m -> m.features[1].start)

        # write models in GFF3 format
        fname = fstrand_features.genome_id * ".gff3";
        if directory !== nothing
            fname = joinpath(directory, fname)
        else
            d = splitpath(infile)
            fname = joinpath(d[1:end - 1]..., fname)
        end
        @info "writing gff3: $fname"
        open(fname, "w") do outfile
            write(outfile, "##gff-version 3.2.1\n")
            for model in models_as_feature_arrays
                writeGFF3(outfile, model)
            end
        end
    end
end
end # module
