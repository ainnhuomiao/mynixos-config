final: prev: {
  pywalfox-native = prev.pywalfox-native.overrideAttrs (old: {
    postInstall = (old.postInstall or "") + ''
      mkdir -p $out/lib/mozilla/native-messaging-hosts
      manifests=( ${prev.pywalfox-native}/lib/python*/site-packages/pywalfox/assets/manifest.json )
      if [ "''${#manifests[@]}" -ne 1 ]; then
        echo "Expected exactly one pywalfox manifest, found ''${#manifests[@]}" >&2
        exit 1
      fi
      substitute "''${manifests[0]}" \
        $out/lib/mozilla/native-messaging-hosts/pywalfox.json \
        --replace '<path>' "$out/bin/pywalfox"
    '';
  });
}
