
let opt_arg cgi s = try Some (cgi#argument s)#value with Not_found -> None  
  
let  handle_get (cgi : Netcgi_fcgi.cgi) =
  Printf.printf "get\n%!";
  List.iter (fun (a,b) -> (Printf.printf "arg %s %s\n%!" a b)) (cgi#environment#cgi_properties);
  List.iter (fun a -> (Printf.printf "arg %s %s\n%!" a#name a#value)) (cgi#arguments);
  cgi#set_header ~cache:`No_cache ~status:`Ok ();
  (*cgi#set_header ~cache:`No_cache ~status:`Unauthorized ();*)
  cgi#out_channel#output_string "Ok";
  cgi#out_channel#commit_work()

let handle_others (cgi : Netcgi_fcgi.cgi) =
  cgi#set_header ~status:`Bad_request ();
  cgi#out_channel#output_string "Bad request.";
  cgi#out_channel#commit_work()

let tokenauth (cgi : Netcgi_fcgi.cgi) =
  match cgi#request_method with
    | `GET -> handle_get cgi
    | _ -> handle_others cgi

let main () = 
  ignore (Sys.signal Sys.sigpipe Sys.Signal_ignore);
  Netcgi_fcgi.run
    ~sockaddr:(Unix.ADDR_INET (Unix.inet_addr_any, 8000))
    ~config:{Netcgi.default_config with Netcgi.default_exn_handler = false}
    tokenauth

let _ = main ()
