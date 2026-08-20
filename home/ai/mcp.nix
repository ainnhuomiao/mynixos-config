{ lib, pkgs, ... }:

let
  context7Url = "https://mcp.context7.com/mcp";
in
{
  home.activation.configureContext7 = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [[ -z "''${DRY_RUN:-}" ]]; then
      codex_config="$HOME/.codex/config.toml"
      ${pkgs.coreutils}/bin/mkdir -p "$HOME/.codex"
      if [[ ! -f "$codex_config" ]]; then
        ${pkgs.coreutils}/bin/touch "$codex_config"
      fi
      codex_tmp="$(${pkgs.coreutils}/bin/mktemp "$HOME/.codex/config.toml.XXXXXX")"
      ${pkgs.gawk}/bin/awk -v url="${context7Url}" '
        function write_context7() {
          if (!context7_written) {
            print "[mcp_servers.context7]"
            print "url = \"" url "\""
            print ""
            context7_written = 1
          }
        }

        /^\[mcp_servers\.context7(\.|\])/ {
          write_context7()
          in_context7 = 1
          next
        }

        /^\[/ && in_context7 {
          in_context7 = 0
        }

        !in_context7 {
          print
        }

        END {
          if (!context7_written) {
            if (NR > 0) {
              print ""
            }
            write_context7()
          }
        }
      ' "$codex_config" > "$codex_tmp"
      if ${pkgs.diffutils}/bin/cmp -s "$codex_config" "$codex_tmp"; then
        ${pkgs.coreutils}/bin/rm "$codex_tmp"
      else
        ${pkgs.coreutils}/bin/chmod --reference="$codex_config" "$codex_tmp"
        ${pkgs.coreutils}/bin/mv "$codex_tmp" "$codex_config"
      fi

      cc_switch_db="$HOME/.cc-switch/cc-switch.db"
      if [[ -f "$cc_switch_db" ]]; then
        ${pkgs.sqlite}/bin/sqlite3 -cmd '.timeout 5000' "$cc_switch_db" \
          "UPDATE mcp_servers
           SET server_config = json_object(
             'type',
             'http',
             'url',
             '${context7Url}'
           )
           WHERE id = 'context7';
           UPDATE proxy_live_backup
           SET original_config = json_set(
             original_config,
             '$.config',
             CAST(readfile('$codex_config') AS TEXT)
           )
           WHERE app_type = 'codex';"
      fi

      claude_config="$HOME/.claude.json"
      ${pkgs.coreutils}/bin/mkdir -p "$HOME"
      if [[ ! -f "$claude_config" ]]; then
        ${pkgs.coreutils}/bin/printf '{}\n' > "$claude_config"
        ${pkgs.coreutils}/bin/chmod 600 "$claude_config"
      fi
      if ! ${pkgs.jq}/bin/jq -e \
        --arg url "${context7Url}" \
        '.mcpServers.context7.type == "http" and .mcpServers.context7.url == $url' \
        "$claude_config" >/dev/null 2>&1; then
        claude_tmp="$(${pkgs.coreutils}/bin/mktemp "$HOME/.claude.json.XXXXXX")"
        ${pkgs.jq}/bin/jq \
          --arg url "${context7Url}" \
          '.mcpServers.context7 = { type: "http", url: $url }' \
          "$claude_config" > "$claude_tmp"
        ${pkgs.coreutils}/bin/chmod --reference="$claude_config" "$claude_tmp"
        ${pkgs.coreutils}/bin/mv "$claude_tmp" "$claude_config"
      fi

      opencode_config_dir="$HOME/.config/opencode"
      opencode_config="$opencode_config_dir/opencode.json"
      ${pkgs.coreutils}/bin/mkdir -p "$opencode_config_dir"
      if [[ ! -f "$opencode_config" ]]; then
        ${pkgs.coreutils}/bin/printf '{"$schema":"https://opencode.ai/config.json"}\n' \
          > "$opencode_config"
      fi
      if ! ${pkgs.jq}/bin/jq -e \
        --arg url "${context7Url}" \
        '.mcp.context7.type == "remote" and .mcp.context7.url == $url' \
        "$opencode_config" >/dev/null 2>&1; then
        opencode_tmp="$(${pkgs.coreutils}/bin/mktemp \
          "$opencode_config_dir/opencode.json.XXXXXX")"
        ${pkgs.jq}/bin/jq \
          --arg url "${context7Url}" \
          '.mcp.context7 = { type: "remote", url: $url }' \
          "$opencode_config" > "$opencode_tmp"
        ${pkgs.coreutils}/bin/chmod --reference="$opencode_config" "$opencode_tmp"
        ${pkgs.coreutils}/bin/mv "$opencode_tmp" "$opencode_config"
      fi

      copilot_config_dir="$HOME/.copilot"
      copilot_config="$copilot_config_dir/mcp-config.json"
      ${pkgs.coreutils}/bin/mkdir -p "$copilot_config_dir"
      if [[ ! -f "$copilot_config" ]]; then
        ${pkgs.coreutils}/bin/printf '{}\n' > "$copilot_config"
      fi
      if ! ${pkgs.jq}/bin/jq -e \
        --arg url "${context7Url}" \
        '.mcpServers.context7.type == "http" and .mcpServers.context7.url == $url' \
        "$copilot_config" >/dev/null 2>&1; then
        copilot_tmp="$(${pkgs.coreutils}/bin/mktemp \
          "$copilot_config_dir/mcp-config.json.XXXXXX")"
        ${pkgs.jq}/bin/jq \
          --arg url "${context7Url}" \
          '.mcpServers.context7 = {
            type: "http",
            url: $url,
            tools: [ "*" ]
          }' \
          "$copilot_config" > "$copilot_tmp"
        ${pkgs.coreutils}/bin/chmod --reference="$copilot_config" "$copilot_tmp"
        ${pkgs.coreutils}/bin/mv "$copilot_tmp" "$copilot_config"
      fi

      antigravity_config_dir="$HOME/.gemini/config"
      antigravity_config="$antigravity_config_dir/mcp_config.json"
      ${pkgs.coreutils}/bin/mkdir -p "$antigravity_config_dir"
      if [[ ! -s "$antigravity_config" ]]; then
        ${pkgs.coreutils}/bin/printf '{}\n' > "$antigravity_config"
      fi
      antigravity_tmp="$(${pkgs.coreutils}/bin/mktemp \
        "$antigravity_config_dir/mcp_config.json.XXXXXX")"
      ${pkgs.jq}/bin/jq \
        --arg context7_url "${context7Url}" \
        --arg mcp_nixos "${pkgs.mcp-nixos}/bin/mcp-nixos" \
        --arg flake_stats_mcp "${pkgs.flake-stats-mcp}/bin/flake-stats-mcp" \
        '.mcpServers.context7 = { serverUrl: $context7_url }
         | .mcpServers["mcp-nixos"] = {
             command: $mcp_nixos,
             args: []
           }
         | .mcpServers["flake-stats-mcp"] = {
             command: $flake_stats_mcp,
             args: []
           }' \
        "$antigravity_config" > "$antigravity_tmp"
      ${pkgs.coreutils}/bin/chmod --reference="$antigravity_config" "$antigravity_tmp"
      ${pkgs.coreutils}/bin/mv "$antigravity_tmp" "$antigravity_config"
    fi
  '';
}
