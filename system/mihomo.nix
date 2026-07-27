{
  pkgs,
  me,
  ...
}:

let
  userName = me.userName;
  configGroup = "mihomo-config";
  configDirectory = "/var/lib/mihomo-config";
  configFile = "${configDirectory}/config.yaml";
  subscriptionsFile = "${configDirectory}/subscriptions.yaml";
  providerDirectory = "${configDirectory}/proxy-providers";
  ruleProviderDirectory = "${configDirectory}/rule-providers";
  legacySubscriptionFile = "${configDirectory}/subscription.url";
  legacyClashTuiProfiles = "/home/${userName}/.config/clashtui/profiles";

  zashboard = pkgs.fetchzip {
    url = "https://github.com/Zephyruso/zashboard/releases/download/v3.16.0/dist.zip";
    hash = "sha256-HnbkkmDJeTE+ynvgLevWuGGRVjUlO8fIAGaPHLHxbj8=";
  };

  generateConfig = pkgs.writeShellApplication {
    name = "mihomo-generate-config";
    runtimeInputs = with pkgs; [
      coreutils
      mihomo
      yq-go
    ];
    text = ''
            umask 007

            if [[ ! -s "${subscriptionsFile}" ]]; then
              echo "Mihomo subscriptions file is missing: ${subscriptionsFile}" >&2
              exit 1
            fi

            yq eval '.subscriptions = (.subscriptions // {})' "${subscriptionsFile}" >/dev/null

            tmp_file="$(mktemp "${configDirectory}/.config.yaml.XXXXXX")"
            trap 'rm -f "$tmp_file"' EXIT

            cat > "$tmp_file" <<'YAML'
      mixed-port: 7890
      allow-lan: false
      bind-address: 127.0.0.1
      mode: rule
      log-level: info
      ipv6: false
      external-controller: 127.0.0.1:9090
      secret: ""
      profile:
        store-selected: true
        store-fake-ip: true
      tun:
        enable: true
        device: Mihomo
        stack: mixed
        auto-route: true
        auto-redirect: true
        auto-detect-interface: true
        strict-route: true
        dns-hijack:
          - any:53
          - tcp://any:53
        route-exclude-address:
          - 10.0.0.0/8
          - 172.16.0.0/12
          - 192.168.0.0/16
          - fc00::/7
      dns:
        enable: true
        ipv6: false
        respect-rules: true
        listen: 0.0.0.0:1053
        enhanced-mode: fake-ip
        fake-ip-range: 198.18.0.1/16
        fake-ip-filter:
          - "*.lan"
          - "*.local"
        default-nameserver:
          - 223.5.5.5
          - 119.29.29.29
        nameserver:
          - https://1.1.1.1/dns-query
          - https://8.8.8.8/dns-query
        nameserver-policy:
          "rule-set:cn-domain":
            - https://dns.alidns.com/dns-query
            - https://doh.pub/dns-query
        proxy-server-nameserver:
          - https://dns.alidns.com/dns-query
          - https://doh.pub/dns-query
      rule-providers:
        cn-domain:
          type: http
          behavior: domain
          format: mrs
          path: ${ruleProviderDirectory}/cn-domain.mrs
          url: https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geosite/cn.mrs
          interval: 86400
          proxy: DIRECT
        cn-ip:
          type: http
          behavior: ipcidr
          format: mrs
          path: ${ruleProviderDirectory}/cn-ip.mrs
          url: https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geoip/cn.mrs
          interval: 86400
          proxy: DIRECT
      proxy-providers: {}
      proxy-groups:
        - name: 节点选择
          type: select
          proxies:
            - DIRECT
      rules:
        - DOMAIN-SUFFIX,lan,DIRECT
        - DOMAIN-SUFFIX,local,DIRECT
        - IP-CIDR,10.0.0.0/8,DIRECT,no-resolve
        - IP-CIDR,172.16.0.0/12,DIRECT,no-resolve
        - IP-CIDR,192.168.0.0/16,DIRECT,no-resolve
        - IP-CIDR6,fc00::/7,DIRECT,no-resolve
        - RULE-SET,cn-domain,DIRECT
        - RULE-SET,cn-ip,DIRECT,no-resolve
        - MATCH,节点选择
      YAML

            provider_count="$(yq eval '.subscriptions | length' "${subscriptionsFile}")"
            if (( provider_count > 0 )); then
              yq eval -i '
                .["proxy-groups"][0].proxies = ["自动选择"] |
                .["proxy-groups"] += [{
                  "name": "自动选择",
                  "type": "url-test",
                  "use": [],
                  "url": "https://www.gstatic.com/generate_204",
                  "interval": 300,
                  "tolerance": 50,
                  "lazy": true
                }]
              ' "$tmp_file"
            fi

      while IFS= read -r name; do
        [[ -n "$name" ]] || continue
        if [[ ! "$name" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
          echo "Invalid subscription name: $name" >&2
          exit 1
        fi
        url="$(SUBSCRIPTION_NAME="$name" yq eval -r '.subscriptions[strenv(SUBSCRIPTION_NAME)].url // ""' "${subscriptionsFile}")"
              if [[ -z "$url" ]]; then
                echo "Subscription URL is empty: $name" >&2
                exit 1
        fi

        provider_name="subscription-$name"
        provider_group="订阅/$name"
        provider_path="${providerDirectory}/$name.yaml"
        provider_prefix="[$name] "

        PROVIDER_NAME="$provider_name" \
              PROVIDER_URL="$url" \
              PROVIDER_GROUP="$provider_group" \
              PROVIDER_PATH="$provider_path" \
              PROVIDER_PREFIX="$provider_prefix" \
                yq eval -i '
                  .["proxy-providers"][strenv(PROVIDER_NAME)] = {
                    "type": "http",
                    "url": strenv(PROVIDER_URL),
                    "path": strenv(PROVIDER_PATH),
                    "interval": 21600,
                    "header": {
                      "User-Agent": ["mihomo"]
                    },
                    "health-check": {
                      "enable": true,
                      "url": "https://www.gstatic.com/generate_204",
                      "interval": 600,
                      "timeout": 5000,
                      "lazy": true
                    },
                    "override": {
                      "additional-prefix": strenv(PROVIDER_PREFIX)
                    }
                  } |
                  .["proxy-groups"][0].proxies += [strenv(PROVIDER_GROUP)] |
            .["proxy-groups"] += [{
              "name": strenv(PROVIDER_GROUP),
              "type": "select",
              "use": [strenv(PROVIDER_NAME)]
            }] |
            .["proxy-groups"][1].use += [strenv(PROVIDER_NAME)]
          ' "$tmp_file"
            done < <(yq eval -r '.subscriptions | keys | .[]' "${subscriptionsFile}")

            if (( provider_count > 0 )); then
              yq eval -i '.["proxy-groups"][0].proxies += ["DIRECT"]' "$tmp_file"
            fi

            yq eval '.' "$tmp_file" >/dev/null
            mihomo -t -d "${configDirectory}" -f "$tmp_file"
            chmod 0640 "$tmp_file"
            mv -f "$tmp_file" "${configFile}"
            trap - EXIT
    '';
  };

  migrateSubscriptions = pkgs.writeShellApplication {
    name = "mihomo-migrate-subscriptions";
    runtimeInputs = with pkgs; [
      coreutils
      gnused
      yq-go
    ];
    text = ''
      if [[ -e "${subscriptionsFile}" ]]; then
        exit 0
      fi

      tmp_file="$(mktemp "${configDirectory}/.subscriptions.yaml.XXXXXX")"
      trap 'rm -f "$tmp_file"' EXIT
      printf 'subscriptions: {}\n' > "$tmp_file"

      add_subscription() {
        local name="$1"
        local url="$2"

        [[ -n "$url" ]] || return 0
        SUBSCRIPTION_NAME="$name" SUBSCRIPTION_URL="$url" \
          yq eval -i \
            '.subscriptions[strenv(SUBSCRIPTION_NAME)].url = strenv(SUBSCRIPTION_URL)' \
            "$tmp_file"
      }

      if [[ -d "${legacyClashTuiProfiles}" ]]; then
        shopt -s nullglob
        for profile in "${legacyClashTuiProfiles}"/*; do
          [[ -f "$profile" ]] || continue
          name="$(basename "$profile" | tr -cs 'A-Za-z0-9._-' '-' | sed 's/^-\+//; s/-\+$//')"
          [[ -n "$name" ]] || continue
          url="$(tr -d '\r\n' < "$profile")"
          add_subscription "$name" "$url"
        done
      fi

      if [[ -s "${legacySubscriptionFile}" ]]; then
        url="$(tr -d '\r\n' < "${legacySubscriptionFile}")"
        if [[ "$(yq eval '.subscriptions.default == null' "$tmp_file")" == true ]]; then
          add_subscription default "$url"
        fi
      fi

      chmod 0600 "$tmp_file"
      mv "$tmp_file" "${subscriptionsFile}"
      trap - EXIT
    '';
  };

  subscriptionManager = pkgs.writeShellApplication {
    name = "mihomo-sub";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      jq
      systemd
      yq-go
    ];
    text = ''
            validate_name() {
              local name="$1"
              [[ "$name" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]
            }

            load_subscriptions() {
              mapfile -t subscriptions < <(
                yq eval -r '.subscriptions | keys | .[]' "${subscriptionsFile}"
              )
            }

            choose_subscription() {
              load_subscriptions
              if (( ''${#subscriptions[@]} == 0 )); then
                echo "当前没有订阅"
                return 1
              fi

              printf '\n'
              for index in "''${!subscriptions[@]}"; do
                printf '%d) %s\n' "$((index + 1))" "''${subscriptions[$index]}"
              done
              printf '0) 返回\n'

              while true; do
                read -r -p "请选择订阅: " selection
                if [[ "$selection" == 0 ]]; then
                  return 1
                fi
                if [[ "$selection" =~ ^[0-9]+$ ]] &&
                  (( selection >= 1 && selection <= ''${#subscriptions[@]} )); then
                  selected_subscription="''${subscriptions[$((selection - 1))]}"
                  return 0
                fi
                echo "无效选择"
              done
            }

            wait_for_regeneration() {
              sleep 1
              if systemctl is-failed --quiet mihomo-config-regenerate.service; then
                echo "配置生成失败，原有配置未被替换" >&2
                systemctl status mihomo-config-regenerate.service --no-pager -l >&2 || true
                return 1
              fi
              if systemctl is-active --quiet mihomo.service; then
                echo "配置已生效，Mihomo 正在运行"
              else
                echo "配置已保存，但 Mihomo 未运行" >&2
                return 1
              fi
            }

            replace_store() {
              local temporary_file="$1"
              chmod 0600 "$temporary_file"
              mv -f "$temporary_file" "${subscriptionsFile}"
              wait_for_regeneration
            }

            show_subscriptions() {
              load_subscriptions
              if (( ''${#subscriptions[@]} == 0 )); then
                echo "当前没有订阅"
                return
              fi

              provider_data="$(curl --fail --silent http://127.0.0.1:9090/providers/proxies || true)"
              printf '\n%-24s %s\n' "订阅" "节点数"
              printf '%-24s %s\n' "------------------------" "------"
              for name in "''${subscriptions[@]}"; do
                provider_name="subscription-$name"
                if [[ -n "$provider_data" ]]; then
                  node_count="$(jq -r --arg name "$provider_name" '.providers[$name].proxies | length // 0' <<< "$provider_data")"
                else
                  node_count="-"
                fi
                printf '%-24s %s\n' "$name" "$node_count"
              done
            }

            add_subscription() {
              read -r -p "订阅名称: " name
              if ! validate_name "$name"; then
                echo "名称只能包含字母、数字、点、下划线和连字符" >&2
                return 1
              fi

              if [[ "$(SUBSCRIPTION_NAME="$name" yq eval '.subscriptions[strenv(SUBSCRIPTION_NAME)] != null' "${subscriptionsFile}")" == true ]]; then
                read -r -p "订阅已存在，是否替换？[y/N] " confirmation
                [[ "$confirmation" =~ ^[Yy]$ ]] || return 0
              fi

              read -r -s -p "订阅 URL: " url
              printf '\n'
              if [[ ! "$url" =~ ^https?:// ]]; then
                echo "URL 必须以 http:// 或 https:// 开头" >&2
                return 1
              fi

              temporary_file="$(mktemp "${configDirectory}/.subscriptions.yaml.XXXXXX")"
              cp "${subscriptionsFile}" "$temporary_file"
              SUBSCRIPTION_NAME="$name" SUBSCRIPTION_URL="$url" \
                yq eval -i \
                  '.subscriptions[strenv(SUBSCRIPTION_NAME)].url = strenv(SUBSCRIPTION_URL)' \
                  "$temporary_file"
              replace_store "$temporary_file"
            }

            remove_subscription() {
              choose_subscription || return 0
              read -r -p "确认删除 $selected_subscription？[y/N] " confirmation
              [[ "$confirmation" =~ ^[Yy]$ ]] || return 0

              temporary_file="$(mktemp "${configDirectory}/.subscriptions.yaml.XXXXXX")"
              cp "${subscriptionsFile}" "$temporary_file"
              SUBSCRIPTION_NAME="$selected_subscription" \
                yq eval -i 'del(.subscriptions[strenv(SUBSCRIPTION_NAME)])' "$temporary_file"
              replace_store "$temporary_file"
            }

            refresh_subscription() {
              choose_subscription || return 0
              curl \
                --fail \
                --silent \
                --show-error \
                --request PUT \
                "http://127.0.0.1:9090/providers/proxies/subscription-$selected_subscription"
              printf '已刷新：%s\n' "$selected_subscription"
            }

            refresh_all() {
              load_subscriptions
              if (( ''${#subscriptions[@]} == 0 )); then
                echo "当前没有订阅"
                return
              fi

              for name in "''${subscriptions[@]}"; do
                curl \
                  --fail \
                  --silent \
                  --show-error \
                  --request PUT \
                  "http://127.0.0.1:9090/providers/proxies/subscription-$name"
                printf '已刷新：%s\n' "$name"
              done
            }

            if [[ ! -s "${subscriptionsFile}" ]]; then
              echo "订阅配置不存在，请先重新构建 NixOS" >&2
              exit 1
            fi

            while true; do
              cat <<'EOF'

      Mihomo 订阅管理
      1) 查看订阅
      2) 添加或替换订阅
      3) 删除订阅
      4) 刷新一个订阅
      5) 刷新全部订阅
      0) 退出
      EOF
              read -r -p "请选择操作: " action
              case "$action" in
                1) show_subscriptions ;;
                2) add_subscription ;;
                3) remove_subscription ;;
                4) refresh_subscription ;;
                5) refresh_all ;;
                0) exit 0 ;;
                *) echo "无效选择" ;;
              esac
            done
    '';
  };
in
{
  services.mihomo = {
    enable = true;
    tunMode = true;
    configFile = configFile;
    webui = zashboard;
  };

  users.groups.${configGroup} = { };
  users.users.${userName}.extraGroups = [ configGroup ];

  systemd.services.mihomo.serviceConfig = {
    SupplementaryGroups = [ configGroup ];
    ReadWritePaths = [ configDirectory ];
  };
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

  environment.systemPackages = [ subscriptionManager ];

  systemd.tmpfiles.rules = [
    "d ${configDirectory} 2770 ${userName} ${configGroup} -"
    "d ${providerDirectory} 2770 ${userName} ${configGroup} -"
    "d ${ruleProviderDirectory} 2770 ${userName} ${configGroup} -"
  ];

  systemd.services.mihomo-config-regenerate = {
    description = "Regenerate Mihomo config after subscription changes";
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.util-linux}/bin/runuser -u ${userName} -- \
        ${generateConfig}/bin/mihomo-generate-config
      chgrp ${configGroup} "${configFile}"
      chmod 0640 "${configFile}"
      systemctl try-restart mihomo.service
    '';
  };

  systemd.paths.mihomo-config-regenerate = {
    description = "Watch Mihomo subscriptions";
    wantedBy = [ "multi-user.target" ];
    pathConfig = {
      PathChanged = subscriptionsFile;
      Unit = "mihomo-config-regenerate.service";
    };
  };

  system.activationScripts.mihomoConfig = {
    deps = [ "users" ];
    text = ''
      install -d -o ${userName} -g ${configGroup} -m 2770 \
        "${configDirectory}" \
        "${providerDirectory}" \
        "${ruleProviderDirectory}"

      ${migrateSubscriptions}/bin/mihomo-migrate-subscriptions
      chown ${userName}:${configGroup} "${subscriptionsFile}"
      chmod 0600 "${subscriptionsFile}"

      ${pkgs.util-linux}/bin/runuser -u ${userName} -- \
        ${generateConfig}/bin/mihomo-generate-config
      chgrp ${configGroup} "${configFile}"
      chmod 0640 "${configFile}"
    '';
  };
}
