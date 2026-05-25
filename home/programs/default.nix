let
  directoryContents = builtins.readDir ./.;
  # Conditionally imported per profile instead of globally:
  # - waybar: Sway desktop only → home/profiles/k-on
  # - wsl:    WSL host only     → home/profiles/yu
  excludeDirs = [
    "waybar"
    "wsl"
  ];
  directories = builtins.filter (
    name: directoryContents."${name}" == "directory" && !(builtins.elem name excludeDirs)
  ) (builtins.attrNames directoryContents);
  modulePaths = map (name: ./. + "/${name}") directories;
in
{
  imports = modulePaths;
}
