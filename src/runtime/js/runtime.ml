(* This file is part of Bisect_ppx, released under the MIT license. See
   LICENSE.md for details, or visit
   https://github.com/aantron/bisect_ppx/blob/master/LICENSE.md. *)



(* Code based on Melange, inherited from BuckleScript:

   https://github.com/melange-re/melange/blob/da421be55e755096403425ed3c260486deab61f3/jscomp/others/node_fs.ml *)
module Node =
struct
  module Fs =
  struct
    external openSync :
      string ->
      ([ `Read [@as "r"]
      | `Read_write [@as "r+"]
      | `Read_write_sync [@as "rs+"]
      | `Write [@as "w"]
      | `Write_fail_if_exists [@as "wx"]
      | `Write_read [@as "w+"]
      | `Write_read_fail_if_exists [@as "wx+"]
      | `Append [@as "a"]
      | `Append_fail_if_exists [@as "ax"]
      | `Append_read [@as "a+"]
      | `Append_read_fail_if_exists [@as "ax+"] ]
      [@string]) ->
      unit = "openSync"
      [@@module "fs"]

    type encoding = [
      | `hex
      | `utf8
      | `ascii
      | `latin1
      | `base64
      | `ucs2
      | `base64
      | `binary
      | `utf16le
    ]

    external writeFileSync : string -> string -> encoding -> unit =
      "writeFileSync"
      [@@val] [@@module "fs"]
  end
end

let get_coverage_data =
  Bisect_common.runtime_data_to_string

let write_coverage_data () =
  match get_coverage_data () with
  | None ->
    ()
  | Some data ->
    let rec create_file attempts =
      let filename = Bisect_common.random_filename ~prefix:"bisect" in
      match Node.Fs.openSync filename `Write_fail_if_exists with
      | exception exn ->
        if attempts = 0 then
          raise exn
        else
          create_file (attempts - 1)
      | _ ->
        Node.Fs.writeFileSync filename data `binary
    in
    create_file 100

let reset_coverage_data =
  Bisect_common.reset_counters

let node_at_exit = [%bs.raw {|
  function (callback) {
    if (typeof process !== 'undefined' && typeof process.on !== 'undefined')
      process.on("exit", callback);
  }
|}]

let exit_hook_added = ref false

let write_coverage_data_on_exit () =
  if not !exit_hook_added then begin
    node_at_exit (fun () -> write_coverage_data (); reset_coverage_data ());
    exit_hook_added := true
  end

let register_file
    ~bisect_file:_ ~bisect_silent:_ ~bisect_sigterm:_ ~filename ~points =
  write_coverage_data_on_exit ();
  Bisect_common.register_file ~filename ~points
