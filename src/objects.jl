module Objects

VERSION < v"0.4-" && using Docile

export Object, Wall, Disk, VerticalWall, HorizontalWall, Event

abstract Object
abstract Wall <: Object

@doc doc"""Type with attributes position(r), velocity, radius, mass and label. Both position and velocity
are vectors. The label attribute corresponds to the cycle within the main loop in which the Disk suffered
its last collision (see simulacionanimada in *main.jl*) """->
type Disk{T<:Number} <: Object
  r::Array{T,1}
  v::Array{T,1}
  radius::T
  m::T
  lastcollision ::Int
end

Disk(r,v,radius) = Disk(r,v,radius,1.0,0) #Fixed mass of 1.0 and label equal to 0 (by default)
Disk(r,v,radius, mass) = Disk(r,v,radius, mass ,0) #Label equal to 0 (by default)

@doc doc"""Type with attributes x and y. x corresponds to its horizontal position in a Cartesian Plane
(just a number) and y represents its initial and final height in the Plane (Array of length equal to 2)."""  ->
type VerticalWall{T<:Number} <:Wall
  x :: T
  y :: Array{T,1}
end

@doc doc"""Type with attributes x and y. x corresponds to its horizontal extension in a Cartesian plane
(initial and final position -Array of length equal to 2- and y corresponds to its vertical position
(a number).""" ->
type HorizontalWall{T<:Number} <:Wall
  x :: Array{T,1}
  y :: T
end


@doc doc"""Type with attributes time, collider1, collider2 and label. The label makes reference to the cycle
within the main loop in which the event was predicted (see simulacionanimada in main.jl)."""->
type Event
  tiempo :: Number
  p1::Disk
  Q ::Object
  predictedcollision :: Int
end

end