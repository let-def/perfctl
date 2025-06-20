(**
  Module `Perfctl`: Control 'perf' profiling from within the program being profiled.

  This module provides functions to dynamically enable and disable profiling
  using the Linux `perf` tool. It allows the program being profiled to control
  when profiling starts and stops, enabling precise profiling of specific code sections.
*)

val is_available : bool
(** Check if the program is running under perfctl.

    This function returns `true` if the program is being profiled by perfctl,
    and `false` otherwise. It can be used to conditionally enable or disable
    profiling based on the current environment.
*)

val enable : unit -> unit
(** Enable profiling if perfctl is available.

    This function enables profiling if the program is running under perfctl.
    If perfctl is not available, this function does nothing.

    The call blocks while waiting for an answer from perf. Execution reumes only after perf confirms the request.
*)

val disable : unit -> unit
(** Disable profiling if perfctl is available.

    This function disables profiling if the program is running under perfctl.
    If perfctl is not available, this function does nothing.

    The call blocks while waiting for an answer from perf. Execution resumes only after perf confirms the request.
*)
