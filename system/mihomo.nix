{
  pkgs,
  me,
  ...
}:

let
  userName = me.userName;
  configDirectory = "/var/lib/mihomo-config";
  configFile = "${configDirectory}/config.yaml";
  subscriptionFile = "${configDirectory}/subscription.url";
  clashtuiDirectory = "/home/${userName}/.config/clashtui";

  syncClashTui = pkgs.writeShellApplication {
    name = "mihomo-sync-clashtui";
    runtimeInputs = with pkgs; [ coreutils ];
    text = ''
      install -d -o ${userName} -g users -m 0700 \
        "${clashtuiDirectory}/profiles" \
        "${clashtuiDirectory}/profile_cache"
      install -o ${userName} -g users -m 0600 "${configFile}" "${clashtuiDirectory}/basic_clash_config.yaml"
      install -o ${userName} -g users -m 0600 "${configFile}" "${clashtuiDirectory}/profile_cache/default.yaml"

      if [[ -s "${subscriptionFile}" ]]; then
        install -o ${userName} -g users -m 0600 "${subscriptionFile}" "${clashtuiDirectory}/profiles/default"
      fi
    '';
  };

  prepareConfig = pkgs.writeShellApplication {
    name = "mihomo-prepare-config";
    runtimeInputs = with pkgs; [
      coreutils
      yq-go
    ];
    text = ''
      source_file="$1"
      target_file="$2"

      if [[ ! -s "$source_file" ]]; then
        echo "Mihomo source config is empty: $source_file" >&2
        exit 1
      fi

      tmp_file="$(mktemp)"
      trap 'rm -f "$tmp_file"' EXIT

      yq eval '
        .["mixed-port"] = 7890 |
        .["allow-lan"] = false |
        .["bind-address"] = "127.0.0.1" |
        .mode = "rule" |
        .["log-level"] = "info" |
        .ipv6 = false |
        .["external-controller"] = "127.0.0.1:9090" |
        .secret = "" |
        .profile.["store-selected"] = true |
        .profile.["store-fake-ip"] = true |
        .tun.enable = true |
        .tun.device = "Mihomo" |
        .tun.stack = "mixed" |
        .tun.["auto-route"] = true |
        .tun.["auto-redirect"] = true |
        .tun.["auto-detect-interface"] = true |
        .tun.["strict-route"] = true |
        .tun.["dns-hijack"] = ["any:53", "tcp://any:53"] |
        .tun.["route-exclude-address"] = [
          "10.0.0.0/8",
          "172.16.0.0/12",
          "192.168.0.0/16",
          "fc00::/7"
        ] |
        .dns.enable = true |
        .dns.ipv6 = false |
        .dns.listen = "0.0.0.0:1053" |
        .dns.["enhanced-mode"] = "fake-ip"
      ' "$source_file" > "$tmp_file"

      yq eval '.' "$tmp_file" >/dev/null
      install -o ${userName} -g clashtui -m 0640 "$tmp_file" "$target_file"
    '';
  };

  updateSubscription = pkgs.writeShellApplication {
    name = "mihomo-update-subscription";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      systemd
      prepareConfig
    ];
    text = ''
      controller_ready=false
      for _ in $(seq 1 30); do
        if curl --silent --fail --max-time 2 http://127.0.0.1:9090/version >/dev/null; then
          controller_ready=true
          break
        fi
        sleep 1
      done

      if [[ "$controller_ready" != true ]]; then
        echo "Mihomo controller did not become ready" >&2
        exit 1
      fi

      sleep 2

      if [[ ! -s "${subscriptionFile}" ]]; then
        echo "Mihomo subscription URL is missing: ${subscriptionFile}" >&2
        exit 1
      fi

      tmp_file="$(mktemp)"
      trap 'rm -f "$tmp_file"' EXIT

      curl \
        --fail \
        --location \
        --retry 3 \
        --connect-timeout 15 \
        --max-time 120 \
        --header 'User-Agent: mihomo' \
        --output "$tmp_file" \
        "$(<"${subscriptionFile}")"

      mihomo-prepare-config "$tmp_file" "${configFile}"
      ${syncClashTui}/bin/mihomo-sync-clashtui
      systemctl try-restart mihomo.service
    '';
  };
in
{
  services.mihomo = {
    enable = true;
    tunMode = true;
    configFile = configFile;
    webui = pkgs.metacubexd;
  };

  users.groups.clashtui = { };

  systemd.services.mihomo.serviceConfig.SupplementaryGroups = [ "clashtui" ];
  systemd.services.mihomo.environment.SAFE_PATHS = configDirectory;

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (
        subject.user == "${userName}" &&
        action.id == "org.freedesktop.systemd1.manage-units" &&
        action.lookup("unit") == "mihomo.service"
      ) {
        return polkit.Result.YES;
      }
    });
  '';

  networking.firewall = {
    checkReversePath = "loose";
    trustedInterfaces = [ "Mihomo" ];
  };

  environment.systemPackages = [ pkgs.clashtui ];

  systemd.tmpfiles.rules = [
    "d ${configDirectory} 2770 ${userName} clashtui -"
  ];

  system.activationScripts.mihomoConfig = {
    deps = [ "users" ];
    text = ''
      install -d -o ${userName} -g clashtui -m 2770 "${configDirectory}"

      if [[ ! -s "${configFile}" ]]; then
        echo "Mihomo configuration is missing: ${configFile}" >&2
        exit 1
      fi

      chgrp -R clashtui "${configDirectory}"
      chmod -R g+rwX "${configDirectory}"
      find "${configDirectory}" -type d -exec chmod g+s {} +
      ${syncClashTui}/bin/mihomo-sync-clashtui
    '';
  };

  systemd.services.mihomo-subscription-update = {
    description = "Update Mihomo subscription and normalized TUN config";
    wants = [ "network-online.target" ];
    after = [
      "network-online.target"
      "mihomo.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${updateSubscription}/bin/mihomo-update-subscription";
    };
  };

  systemd.timers.mihomo-subscription-update = {
    description = "Daily Mihomo subscription update";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "10min";
      OnUnitActiveSec = "24h";
      RandomizedDelaySec = "15min";
      Persistent = true;
    };
  };
}
