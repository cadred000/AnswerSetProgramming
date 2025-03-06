#const t = 20.
#const max_u = 10.
time(0..t).

prev(T, U) :- time(T), U = T - 1, U >= 0.

dir(1, 0).
dir(-1, 0).
dir(0, 1).
dir(0, -1).

cell(X, Y) :- init(object(node, N), value(at, pair(X, Y))).
grid(X, Y) :- cell(X, Y).

robot(R) :- init(object(robot, R), value(at, pair(X, Y))).
shelf(S) :- init(object(shelf, S), value(at, pair(X, Y))).
highway(X, Y) :- init(object(highway, H), value(at, pair(X, Y))).
picking_station(P, X, Y) :- init(object(pickingStation, P), value(at, pair(X, Y))).
product(I) :- init(object(product, I), A).
order(O) :- init(object(order, O), A).

prod_qty(I, S, Q) :- init(object(product, I), value(on, pair(S, Q))).
order_req(O, I, Q) :- init(object(order, O), value(line, pair(I, Q))).
order_station(O, P) :- init(object(order, O), value(pickingStation, P)).

pos(robot, R, X, Y, 0) :- init(object(robot, R), value(at, pair(X, Y))).
pos(shelf, S, X, Y, 0) :- init(object(shelf, S), value(at, pair(X, Y))).

{ move(R, DX, DY, T) : dir(DX, DY)
; pickup(R, T)
; deliver(R, O, I, U, T) : order(O), product(I), U = 1..max_u
; putdown(R, T)
; idle(R, T)
} = 1 :- robot(R), time(T), T > 0.

occurs(object(robot, R), move(DX, DY), T) :- move(R, DX, DY, T).
occurs(object(robot, R), pickup, T)         :- pickup(R, T).
occurs(object(robot, R), deliver(O, I, U), T)  :- deliver(R, O, I, U, T).
occurs(object(robot, R), putdown, T)          :- putdown(R, T).
occurs(object(robot, R), idle, T)             :- idle(R, T).

pos(robot, R, X1, Y1, T) :- time(T), prev(T, U), pos(robot, R, X, Y, U),
                           move(R, DX, DY, T),
                           X1 = X + DX, Y1 = Y + DY,
                           grid(X1, Y1).

pos(robot, R, X, Y, T) :- time(T), prev(T, U), pos(robot, R, X, Y, U),
                           idle(R, T).

carrying_robot(R, T) :- carrying(R, S, T).
free(R, T) :- robot(R), time(T), not carrying_robot(R, T).

carrying(R, S, T) :- time(T), prev(T, U), pickup(R, T),
                     pos(robot, R, X, Y, U),
                     pos(shelf, S, X, Y, U),
                     free(R, U).

carrying(R, S, T) :- time(T), prev(T, U), carrying(R, S, U),
                     not putdown(R, T).

dropped(R, S, T) :- time(T), prev(T, U), putdown(R, T), carrying(R, S, U).

pos(shelf, S, X, Y, T) :- time(T), carrying(R, S, T), pos(robot, R, X, Y, T).
pos(shelf, S, X, Y, T) :- time(T), prev(T, U), pos(shelf, S, X, Y, U),
                          not pickup_occurs(S, T).

pickup_occurs(S, T) :- time(T), prev(T, U), pickup(R, T), pos(shelf, S, XX, YY, U).

:- time(T), deliver(R, O, I, U, T), prev(T, U), free(R, U).
:- time(T), deliver(R, O, I, U, T), prev(T, U), pos(robot, R, X, Y, U),
   order_station(O, P), picking_station(P, Xp, Yp), X != Xp.
:- time(T), deliver(R, O, I, U, T), prev(T, U), pos(robot, R, X, Y, U),
   order_station(O, P), picking_station(P, Xp, Yp), Y != Yp.
:- time(T), deliver(R, O, I, U, T), prev(T, U), carrying(R, S, U),
   prod_qty(I, S, Q), Q < U.
:- time(T), deliver(R, O, I, U, T), order_req(O, I, RQ), RQ < U.

:- time(T), putdown(R, T), prev(T, U), free(R, U).
:- time(T), putdown(R, T), prev(T, U), pos(robot, R, X, Y, U),
   highway(X, Y).

:- time(T), pos(robot, R1, X, Y, T),
   pos(robot, R2, X, Y, T), R1 != R2.

non_idle_exists :- occurs(object(robot, R), A, T), A != idle.
:- not non_idle_exists.

used(T) :- occurs(object(robot, R), A, T), A != idle.
later_used(T) :- time(T), used(T2), T2 > T.
last(T) :- used(T), not later_used(T).
#minimize { T : last(T) }.
