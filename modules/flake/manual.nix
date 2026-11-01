{
  # `dots-manual`: the manual in docs/manual/, from anywhere in the checkout.
  # With no argument it serves the book on localhost:3000 and opens it in the
  # browser, rebuilding on every edit; `dots-manual build` renders it once into
  # docs/manual/book/. Further arguments go to mdbook (`dots-manual serve -p 3001`).
  perSystem =
    { pkgs, ... }:
    {
      packages.dots-manual = pkgs.writeShellApplication {
        name = "dots-manual";
        runtimeInputs = with pkgs; [
          mdbook
          git
        ];
        text = ''
          root="$(git rev-parse --show-toplevel)"
          case "''${1:-}" in
            "")
              exec mdbook serve "$root/docs/manual" --open
              ;;
            serve | build | clean | test)
              command="$1"
              shift
              exec mdbook "$command" "$root/docs/manual" "$@"
              ;;
            *)
              echo "usage: dots-manual [serve|build|clean|test] [mdbook arguments]" >&2
              exit 2
              ;;
          esac
        '';
      };
    };
}
