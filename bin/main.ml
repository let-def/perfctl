(*
  MIT License

  Copyright (c) 2025 Frédéric Bour

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
*)

let usage oc =
  Printf.fprintf oc
    "Usage: %s [-e] [record | stat] <perf args> <command line>\n\n\
    \n\
    Options:\n\
    \  -e, --enabled Start profiling immediately\n\n\
    Trace a command with perf such that profiling can be controlled from OCaml's perfctl library.\n\
    For instance:\n\
    \  perfctl record my-ocaml-command\n\
    \  perfctl stat my-ocaml-command\n"
    Sys.argv.(0)

let start_enabled = ref false

(* Extract command line arguments *)
let perf_action, perf_args =
  let rec loop = function
    | ["-h"] | ["-help"] | ["--help"] ->
      usage stdout;
      exit 0

    | ("-e" | "--enabled") :: rest ->
      start_enabled := true;
      loop rest

    | ("record" | "stat" as action) :: args ->
      (action, args)

    | x :: _ ->
      prerr_endline ("perfctl: unexpected argument " ^ x);
      usage stderr;
      exit 1

    | [] ->
      usage stderr;
      exit 1

  in
  loop (List.tl (Array.to_list Sys.argv))

(* Create file descriptors *)

let fd_ctl_read, fd_ctl_write = Unix.pipe ~cloexec:false ()
let fd_ack_read, fd_ack_write = Unix.pipe ~cloexec:false ()

(* We need to workaround Unix.file_descr being abstract ¯\_(ツ)_/¯ *)

let int_of_file_descr : Unix.file_descr -> int = Obj.magic

(* Setup environment *)

let () = Unix.putenv "PERFCTL_CTL_FD" (string_of_int (int_of_file_descr fd_ctl_write))
let () = Unix.putenv "PERFCTL_ACK_FD" (string_of_int (int_of_file_descr fd_ack_read))

(* Exec perf *)

let control_arg = [
  "--control";
  Printf.sprintf "fd:%d,%d"
    (int_of_file_descr fd_ctl_read)
    (int_of_file_descr fd_ack_write)
]

let control_arg =
  if !start_enabled
  then control_arg
  else "--delay=-1" :: control_arg

let () =
  try
    Unix.execvp "perf"
      (Array.of_list (List.flatten [["perf"; perf_action]; control_arg; perf_args]))
  with
  | Unix.Unix_error(Unix.ENOENT, "execvp", "perf") ->
    Printf.eprintf "Cannot execute 'perf'. Please make sure the command is available.\n";
    exit 1

  | exn ->
    Printf.eprintf "Unknown error while executing perf (%S). Please make sure the command is available.\n"
      (Printexc.to_string exn);
    exit 1
