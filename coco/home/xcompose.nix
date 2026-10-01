{ lib, ... }:

let
  # Dead keys on the base levels of us(intl) and the character each one types.
  deadKeys = {
    dead_acute = "'";
    dead_grave = "`";
    dead_tilde = "~";
    dead_circumflex = "^";
    dead_diaeresis = ''\"'';
  };

  # The only dead key combinations that compose (pt-BR and German); everything else passes through.
  composed = {
    dead_acute = {
      a = "á";
      e = "é";
      i = "í";
      o = "ó";
      u = "ú";
      c = "ç";
      A = "Á";
      E = "É";
      I = "Í";
      O = "Ó";
      U = "Ú";
      C = "Ç";
    };
    dead_grave = {
      a = "à";
      A = "À";
    };
    dead_tilde = {
      a = "ã";
      o = "õ";
      A = "Ã";
      O = "Õ";
    };
    dead_circumflex = {
      a = "â";
      e = "ê";
      o = "ô";
      A = "Â";
      E = "Ê";
      O = "Ô";
    };
    dead_diaeresis = {
      a = "ä";
      e = "ë";
      o = "ö";
      u = "ü";
      A = "Ä";
      E = "Ë";
      O = "Ö";
      U = "Ü";
    };
  };

  letters = lib.stringToCharacters "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
  digits = lib.stringToCharacters "0123456789";

  # Keysym name -> character, for printable ASCII other than letters and digits.
  punctuation = {
    exclam = "!";
    quotedbl = ''\"'';
    numbersign = "#";
    dollar = "$";
    percent = "%";
    ampersand = "&";
    apostrophe = "'";
    parenleft = "(";
    parenright = ")";
    asterisk = "*";
    plus = "+";
    comma = ",";
    minus = "-";
    period = ".";
    slash = "/";
    colon = ":";
    semicolon = ";";
    less = "<";
    equal = "=";
    greater = ">";
    question = "?";
    at = "@";
    bracketleft = "[";
    backslash = ''\\'';
    bracketright = "]";
    asciicircum = "^";
    underscore = "_";
    grave = "`";
    braceleft = "{";
    bar = "|";
    braceright = "}";
    asciitilde = "~";
  };

  keys =
    lib.genAttrs (letters ++ digits) lib.id
    // punctuation
    # Pressing a dead key twice types its character twice.
    // deadKeys;

  rulesFor =
    dead: accent:
    lib.mapAttrsToList (
      key: char:
      let
        out = composed.${dead}.${key} or (if key == dead then accent + accent else accent + char);
      in
      ''<${dead}> <${key}> : "${out}"''
    ) (lib.filterAttrs (key: _: key == dead || !(deadKeys ? ${key})) keys);
in
{
  home.file.".XCompose".text = ''
    include "%L"

    ${lib.concatStringsSep "\n" (lib.concatLists (lib.mapAttrsToList rulesFor deadKeys))}
  '';
}
