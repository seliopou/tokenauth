all:
	ocamlfind ocamlopt -o tokenauth -linkpkg -package netcgi2 src/main.ml
