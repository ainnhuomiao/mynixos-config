{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "cloudflare-speedtest";
  version = "v2.3.5";

  src = fetchFromGitHub {
    owner = "XIU2";
    repo = "CloudflareSpeedTest";
    rev = version;
    sha256 = "0mj9bfx4y2xlvg1zq9b5b8lv4dlmca68dk20ni2hx7mnh1ffzwhb";
  };

  vendorHash = "sha256-4h3Jf3K6uEm79KAy46v69wby01zf2tfdZxGeTyUXvdk=";

  subPackages = [ "." ];

  ldflags = [
    "-w"
    "-s"
    "-X main.version=${version}"
  ];

  # 默认 -f 是相对当前目录的 ip.txt；把内置 IP 段装进 share，
  # 并用 wrapper 在用户未显式传 -f/-ip/-h/-v 时自动指向它（开箱即用）
  postInstall = ''
    install -Dm644 ip.txt ipv6.txt -t $out/share/cloudflare-speedtest
    mv $out/bin/CloudflareSpeedTest $out/bin/.cloudflare-speedtest-real
    cat > $out/bin/cloudflare-speedtest <<EOF
    #!/usr/bin/env bash
    for a in "\$@"; do
      case "\$a" in
        -f|-f=*|-ip|-ip=*|-h|-v)
          exec $out/bin/.cloudflare-speedtest-real "\$@"
          ;;
      esac
    done
    exec $out/bin/.cloudflare-speedtest-real -f $out/share/cloudflare-speedtest/ip.txt "\$@"
    EOF
    chmod +x $out/bin/cloudflare-speedtest
  '';

  meta = with lib; {
    description = "自选优选 IP：测速并筛选 Cloudflare CDN 最快 IP (IPv4+IPv6)，也支持其他 CDN";
    homepage = "https://github.com/XIU2/CloudflareSpeedTest";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    mainProgram = "cloudflare-speedtest";
  };
}
