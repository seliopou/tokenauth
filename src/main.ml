let db = Dbm.opendbm "tokens.bdb" [Dbm.Dbm_rdwr; Dbm.Dbm_create] 0o666

let token length =
  Random.self_init ();
  let gen () = match Random.int(26+26+10) with
    | n when n < 26 -> int_of_char 'a' + n
    | n when n < 26 + 26 -> int_of_char 'A' + n - 26
    | n -> int_of_char '0' + n - 26 - 26 in
  let gen _ = String.make 1 (char_of_int (gen ())) in
  String.concat "" (Array.to_list (Array.init length gen));;

let opt_arg cgi s = try Some (cgi#argument s)#value with Not_found -> None  

let email (cgi : Netcgi_fcgi.cgi) addr =
  let tkn = token 10 in
  let msg = Netsendmail.compose
    ~from_addr:("Token bot", "webmaster@example.com") 
    ~to_addrs:["", addr]
    ~subject:"Token"
    ("Your token:\t" ^ tkn ^ "\nLink: http://127.0.0.1/auth?t=" ^ tkn)
  in
  let serveraddr = `Socket 
    (`Sock_inet_byname(Unix.SOCK_STREAM, "lc", 25), Uq_client.default_connect_options) in
  let client = new Netsmtp.connect serveraddr 5.0 in
  Netsmtp.authenticate client;
  Netsmtp.sendmail client msg;

  Dbm.replace db tkn (Marshal.to_string (addr, Unix.time ()) []);

  cgi#set_header ~cache:`No_cache ~status:`Ok ();
  cgi#out_channel#output_string "Email sent";
  cgi#out_channel#commit_work()

let filter_tokens k v = 
  let ((user: string), (time: float)) = Marshal.from_string v 0 in
  if time < Unix.time () -. 600.0 then Dbm.remove db k

let verification (cgi : Netcgi_fcgi.cgi) tkn =
  Dbm.iter filter_tokens db;
  let ((user: string), (time: float)) = try
    Marshal.from_string (Dbm.find db tkn) 0
    with Not_found -> ("", 0.0) in
  if user <> "" then
    begin
      Dbm.replace db tkn (Marshal.to_string (user, Unix.time ()) []);
      cgi#set_header ~cache:`No_cache ~set_cookies:[Netcgi.Cookie.make "token" tkn] ~status:`Ok ()
    end
  else
    cgi#set_header ~cache:`No_cache ~set_cookies:[] ~status:`Ok ();
  cgi#out_channel#output_string ("Ok " ^ user ^ " " ^ string_of_float time);
  cgi#out_channel#commit_work()

let authorisation (cgi : Netcgi_fcgi.cgi) =
  cgi#set_header ~cache:`No_cache ~set_cookies:[] ~status:`Ok ();
  (*cgi#set_header ~cache:`No_cache ~status:`Unauthorized ();*)
  cgi#out_channel#output_string "Ok";
  cgi#out_channel#commit_work()

let handle_get (cgi : Netcgi_fcgi.cgi) =
  (*List.iter (fun (a,b) -> (Printf.printf "env %s %s\n%!" a b)) (cgi#environment#cgi_properties);
  List.iter (fun a -> (Printf.printf "arg %s %s\n%!" a#name a#value)) (cgi#arguments);*)
  match opt_arg cgi "email" with
  | Some e -> email cgi e
  | None ->
    match opt_arg cgi "t" with
    | Some t -> verification cgi t
    | _ -> authorisation cgi

let handle_others (cgi : Netcgi_fcgi.cgi) =
  cgi#set_header ~status:`Bad_request ~set_cookies:[] ();
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

let _ =
  main ();
  Dbm.close db
