final: prev:

{
  mcp-nixos = prev.mcp-nixos.overrideAttrs (old: {
    disabledTests = (old.disabledTests or [ ]) ++ [
      # This test scans an arbitrary text file from /nix/store and mistakes
      # normal source code containing the word "Error" for a read failure.
      "test_read_text_file"
    ];
  });
}
