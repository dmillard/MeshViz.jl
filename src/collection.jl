# ------------------------------------------------------------------
# Licensed under the MIT License. See LICENSE in the project root.
# ------------------------------------------------------------------

Makie.plottype(::Collection) = Viz{<:Tuple{Collection}}

function Makie.plot!(plot::Viz{<:Tuple{Collection}})
  # retrieve collection object
  collection = plot[:object][]

  size         = plot[:size][]
  color        = plot[:color][]
  alpha        = plot[:alpha][]
  colorscheme  = plot[:colorscheme][]
  facetcolor   = plot[:facetcolor][]
  showfacets   = plot[:showfacets][]
  decimation   = plot[:decimation][]

  # process color spec into colorant
  colorant = process(color, colorscheme, alpha)

  # decimate geometries if needed
  geoms = decimation > 0 ? decimate.(collection, decimation) : collect(collection)

  # retrieve parametric dimension
  ranks = paramdim.(geoms)

  if all(ranks .== 0)
    # visualize point set
    coords = coordinates.(geoms)
    Makie.scatter!(plot, coords,
      color = colorant,
      markersize = size,
    )
  elseif all(ranks .== 1)
    vizmany!(plot, discretize.(geoms))
  elseif all(ranks .== 2)
    vizmany!(plot, discretize.(geoms))
  elseif all(ranks .== 3)
    bounds = boundary.(geoms)
    vizmany!(plot, discretize.(bounds))
  else # mixed dimension
    # visualize subsets of equal rank
    inds3 = findall(g -> paramdim(g) == 3, geoms)
    inds2 = findall(g -> paramdim(g) == 2, geoms)
    inds1 = findall(g -> paramdim(g) == 1, geoms)
    inds0 = findall(g -> paramdim(g) == 0, geoms)
    isempty(inds3) || viz!(plot, Collection(geoms[inds3]))
    isempty(inds2) || viz!(plot, Collection(geoms[inds2]))
    isempty(inds1) || viz!(plot, Collection(geoms[inds1]))
    isempty(inds0) || viz!(plot, Collection(geoms[inds0]))
  end

  if showfacets
    bounds = filter(!isnothing, boundary.(geoms))
    if isempty(bounds)
      # nothing to be done
    elseif all(ranks .== 1)
      # all boundaries are point sets
      points = mapreduce(collect, vcat, bounds)
      viz!(plot, Collection(points),
        color = facetcolor,
        showfacets = false,
      )
    elseif all(ranks .== 2)
      # all boundaries are geometries
      viz!(plot, Collection(bounds),
        color = facetcolor,
        showfacets = false,
      )
    elseif all(ranks .== 3)
      # we already visualized the boundaries because
      # that is all we can do with 3D geometries
    end
  end
end