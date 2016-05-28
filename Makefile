all:
	ocamlfind ocamlopt -o tokeauth -linkpkg -package netcgi2 src/main.ml
