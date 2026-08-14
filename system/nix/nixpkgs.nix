{
  self,
  inputs,
  ...
}:
{
  nixpkgs = {
    config = {
      allowBroken = true;
      allowUnsupportedSystem = true;
      allowUnfree = true;
      permittedInsecurePackages = [
        "electron-39.8.10"
      ];
    };
    overlays = [
      self.overlays.default
      # llm-agents.nix：全部 AI 编码工具位于 pkgs.llm-agents.* 命名空间，
      # 与 nixpkgs 及本仓库自定义包不冲突
      inputs.llm-agents.overlays.shared-nixpkgs
      inputs.rust-overlay.overlays.default
      inputs.nur.overlays.default
    ];
  };
}
