# Waybar RPM 与 Hyprland Lua 工作区

此目录保留当前 Fedora 43 本地包的构建输入：Waybar 0.15.0、Fedora 打包配置，以及工作区点击使用 Lua 分发接口的补丁。事件连接使用 0.15.0 上游实现。

`waybar.spec` 与 `waybar-fedora-config-changes.patch` 基于 [Fedora f43 的 Waybar 打包源](https://src.fedoraproject.org/rpms/waybar/tree/f43)。`waybar-lua-workspaces.patch` 修改六处工作区点击分发；本机工作区使用数字名称。

准备 spec 中声明的构建依赖及 `rpm-build`，然后在本目录运行：

```sh
build_root=$(mktemp -d /tmp/waybar-rpm.XXXXXX)
mkdir -p "$build_root"/{SOURCES,SPECS,BUILD,BUILDROOT,RPMS,SRPMS}
cp waybar.spec "$build_root/SPECS/"
cp ./*.patch "$build_root/SOURCES/"
curl --fail --location https://github.com/Alexays/Waybar/archive/refs/tags/0.15.0.tar.gz \
  --output "$build_root/SOURCES/waybar-0.15.0.tar.gz"
env -u HYPRLAND_INSTANCE_SIGNATURE rpmbuild --define "_topdir $build_root" -bb "$build_root/SPECS/waybar.spec"
```

生成的 RPM 位于 `$build_root/RPMS/`。构建过程包含上游测试；不应将当前桌面会话的 `HYPRLAND_INSTANCE_SIGNATURE` 传给测试。后续更新 Waybar 或 Hyprland 时，需要重新核对补丁是否适用，并验证点击、快捷键切换后的高亮和事件连接。
