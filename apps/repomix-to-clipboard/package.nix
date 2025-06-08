{ pkgs }:

pkgs.writeScriptBin "repomix-to-clipboard" ''
  #!${pkgs.bash}/bin/bash
  set -euo pipefail

  echo "Running repomix and copying output to clipboard..."

  # Run repomix in the current directory
  ${pkgs.repomix}/bin/repomix --style xml --output repomix-output.xml

  # Copy the output to clipboard
  if [ -f "repomix-output.xml" ]; then
    ${pkgs.wl-clipboard}/bin/wl-copy < repomix-output.xml
    echo "✅ Repomix output copied to clipboard"
  else
    echo "❌ Error: repomix-output.xml not found"
    exit 1
  fi
''

