all:
	ocamlfind ocamlopt -o tokenauth -linkpkg -package netcgi2,netclient,dbm src/main.ml
