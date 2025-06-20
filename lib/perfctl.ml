(* We need to workaround Unix.file_descr being abstract ¯\_(ツ)_/¯ *)

let file_descr_of_int : int -> Unix.file_descr = Obj.magic

(* Setup environment *)

let import_fd fn text =
  Option.map (fun fd -> fn (file_descr_of_int fd)) (int_of_string_opt text)

let fd_ctl_write =
  Option.bind
    (Sys.getenv_opt "PERFCTL_CTL_FD")
    (import_fd Unix.out_channel_of_descr)

let fd_ack_read =
  Option.bind
    (Sys.getenv_opt "PERFCTL_ACK_FD")
    (import_fd Unix.in_channel_of_descr)

let is_available = Option.is_some fd_ctl_write && Option.is_some fd_ack_read

let send_and_ack_command cmd =
  match fd_ctl_write, fd_ack_read with
  | Some w, Some r ->
    output_string w cmd;
    flush w;
    begin match input_line r with
    | "\000ack" | "ack" -> ()
    | str -> Printf.eprintf "perfctl: unexpected answer from perf (%S)\n" str
    end
  | _ -> ()

let enable () = send_and_ack_command "enable\n"

let disable () = send_and_ack_command "disable\n"
