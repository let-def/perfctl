
(* Is the program running under perfctl? *)
val is_available : bool

(* Enable profiling if [is_available] is true.
   Otherwise, do nothing.

   This call blocks while waiting for an answer from perf. *)

val enable : unit -> unit

(* Disable profiling if [is_available] is true.
   Otherwise, do nothing.

   This call blocks while waiting for an answer from perf. *)

val disable : unit -> unit
