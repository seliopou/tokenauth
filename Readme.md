# Tokenauth

Authenticate your (web) application's users using tokens.
Designed to be used as a standalone process or an OCaml libray.
Written in OCaml because [it rocks](https://github.com/rizo/awesome-ocaml)

Instead of passwords, _tokenauth_ verifies the user's identity using email.
The email contains a token and a link based on this token.

It can used to protect access to pages, comment posting, etc.

## Web server configuration

For web environments, _tokenauth_ runs as a FastCGI process.
Web servers delegate request authentication and signing-in to _tokenauth_.

### Nginx configuration

For every path you wish to protect, delegate authentication to _tokenauth_ with `auth_request`.
_Tokenauth_ doesn't check the request path, only the query parameters `t` (for token) and `email`.

The example below protects `/private` and defines two paths, one for signing-in and one for authentication.
_Tokenauth_ runs on localhost on port 8000.
The path `/auth` is meant to be used only internally for authenticating requests.
The path `/signin` is where forms should submit the user's email.

    location ~ /private {
        auth_request /auth;
    }

    location ~ /signin {
        include fastcgi_params;
        fastcgi_param TOKEN $cookie_test if_not_empty;
        fastcgi_pass_request_headers on;
        fastcgi_pass 127.0.0.1:8000;
    }

    location = /auth {
        include fastcgi_params;
        fastcgi_param TOKEN $cookie_test if_not_empty;
        fastcgi_pass_request_headers on;
        fastcgi_pass 127.0.0.1:8000;
    }

