include("./objects.jl")
include("./timesandrules.jl")
include("./creatingobjects.jl")

module HardDisksSimulation

VERSION < v"0.4-" && using Docile

importall Objects
importall Rules
importall Init
import Base.isless
export simulation, energy

#This allow to use the PriorityQueue providing a criterion to select the priority of an Event.
isless(e1::Event, e2::Event) = e1.tiempo < e2.tiempo

@doc doc"""Calculates the initial feasible Events and push them into the PriorityQueue with label
equal to 0"""->
function initialcollisions!(particulas::Array, paredes::Array, tinicial::Number, tmax::Number, pq)
    #Puts the initial label of the
    for i in 1:length(particulas)
        tiempo = zeros(4)
        indice = 1
        for pared in paredes
            dt = dtcollision(particulas[i], pared)
            tiempo[indice] = dt
            indice += 1
        end
        dt,k = findmin(tiempo)
        if tinicial + dt < tmax
            Collections.enqueue!(pq,Event(tinicial+dt, particulas[i], paredes[k],0),tinicial+dt)
        end
        for j in i+1:length(particulas) #Numero de pares sin repetición N(N-1)/2
            dt = dtcollision(particulas[i], particulas[j])
            if tinicial + dt < tmax
                Collections.enqueue!(pq,Event(tinicial+dt, particulas[i], particulas[j],0),tinicial+dt)
            end
        end
    end
    pq
end


@doc doc"""Updates the PriorityQueue pushing into it all the feasible Events that can occur after the collision
of a Disk with a Wall"""->
function futurecollisions!(particula, particulas, paredes, tinicial, tmax, pq, etiqueta )
    tiempo = zeros(4)
    indice = 1
    for pared in paredes
        dt = dtcollision(particula, pared)
        tiempo[indice] = dt
        indice += 1
    end
    dt,k = findmin(tiempo)
    if tinicial + dt < tmax
        Collections.enqueue!(pq,Event(tinicial+dt, particula, paredes[k], etiqueta),tinicial+dt)
    end

    tiempo = Float64[]
    for p in particulas
        if particula != p
            dt = dtcollision(particula, p)
            if tinicial + dt < tmax
                Collections.enqueue!(pq,Event(tinicial+dt, particula, p, etiqueta),tinicial+dt)
            end
        end
    end
    pq
end

@doc doc"""Updates the PriorityQueue pushing into it all the possible Events that can occur after the collision
of two Disks."""->
function futurecollisions!(particula1, particula2, particulas, paredes, tinicial, tmax, pq, etiqueta)

    tiempo = zeros(4)
    indice = 1
    for pared in paredes
        dt = dtcollision(particula1, pared)
        tiempo[indice] = dt
        indice += 1
    end
    dt,k = findmin(tiempo)
    if tinicial + dt < tmax
        Collections.enqueue!(pq,Event(tinicial+dt, particula1, paredes[k], etiqueta),tinicial+dt)
    end

    tiempo = zeros(4)
    indice = 1
    for pared in paredes
        dt = dtcollision(particula2, pared)
        tiempo[indice] = dt
        indice += 1
    end
    dt,k = findmin(tiempo)
    if tinicial + dt < tmax
        Collections.enqueue!(pq,Event(tinicial+dt, particula2, paredes[k], etiqueta),tinicial+dt)
    end

    #Voy a considerar que no hay recolisión entre las partículas que acaban de chocar, por consiguiente ajusto el tiempo de colisión entre disk1 y
    #disk2 igual a infinito.
    tiempo = Float64[]
    for p in particulas
        if (particula1 != p) & (particula2 != p)
            dt = dtcollision(particula1, p)
            if tinicial + dt < tmax
                Collections.enqueue!(pq,Event(tinicial+dt, particula1, p, etiqueta),tinicial+dt)
            end
        end
    end

    tiempo = Float64[]
    for p in particulas
        if (particula1 != p) & (particula2 != p)
            dt = dtcollision(particula2, p)
            if tinicial + dt < tmax
                Collections.enqueue!(pq,Event(tinicial+dt, particula2, p, etiqueta),tinicial+dt)
            end
        end
    end
    pq
end

@doc doc"""Calculates the total energy (kinetic) of the system."""->
function energy(masas,velocidades)
    e = 0.
    for i in 1:length(masas)
        e += masas[i]*norm(velocidades[i])^2/2.
    end
    e
end

function startingsimulation(tinicial, tmax, N, Lx1, Lx2, Ly1, Ly2, vmin, vmax)
    particulas = createdisks(N,Lx1,Lx2,Ly1,Ly2,vmin,vmax)
    paredes = createwalls(Lx1,Lx2,Ly1,Ly2)
    posiciones = [particula.r for particula in particulas]
    velocidades = [particula.v for particula in particulas]
    masas = [particula.mass for particula in particulas]
    pq = Collections.PriorityQueue()
    Collections.enqueue!(pq,Event(0.0, Disk([0.,0.],[0.,0.],1.0),Disk([0.,0.],[0.,0.],1.0), 0),0.)
    pq = initialcollisions!(particulas,paredes,tinicial,tmax, pq)
    evento = Collections.dequeue!(pq)
    t = evento.tiempo
    tiempo = [evento.tiempo]
    return particulas, paredes, posiciones, velocidades, masas, pq, t, tiempo
end



@doc doc"""Contains the main loop of the project. The PriorityQueue is filled at each step with Events associated
to the collider Disk(s); and at the same time the element with the highest physical priority (lowest time) is removed
from the Queue and ignored if it is physically meaningless. The loop goes until the last Event is removed
from the Data Structure, which is delimited by the maximum time(tmax)."""->
function simulation(tinicial, tmax, N, Lx1, Lx2, Ly1, Ly2, vmin, vmax)
    particulas, paredes, posiciones, velocidades, masas, pq, t, tiempo = startingsimulation(tinicial, tmax, N, Lx1, Lx2, Ly1, Ly2, vmin, vmax)
    label = 0

    while(!isempty(pq))
        label += 1
        evento = Collections.dequeue!(pq)
        if (evento.predictedcollision >= evento.referencedisk.lastcollision)
            if typeof(evento.diskorwall) == Disk
                if (evento.predictedcollision >= evento.diskorwall.lastcollision)
                    evento.diskorwall.lastcollision = label
                    evento.referencedisk.lastcollision = label
                    for particula in particulas
                        move(particula,evento.tiempo - t)
                    end
                    t = evento.tiempo
                    push!(tiempo,t)
                    collision(evento.referencedisk,evento.diskorwall)
                    for i in 1:N
                        push!(posiciones, particulas[i].r)
                        push!(velocidades, particulas[i].v)
                    end
                    futurecollisions!(evento.referencedisk, evento.diskorwall, particulas, paredes, t, tmax, pq,label)
                end
            else
                evento.referencedisk.lastcollision = label
                for particula in particulas
                    move(particula,evento.tiempo - t)
                end
                t = evento.tiempo
                push!(tiempo,t)
                collision(evento.referencedisk,evento.diskorwall)
                for i in 1:N
                    push!(posiciones, particulas[i].r)
                    push!(velocidades, particulas[i].v)
                end
                futurecollisions!(evento.referencedisk, particulas, paredes, t, tmax, pq, label)
            end
        end
    end
    push!(tiempo, tmax)
    posiciones, velocidades, tiempo, particulas, masas
end


end
