# jouer

fedora atomic image with cinnamon and nvidia 470xx drivers for kepler cards (gtx 660 ti etc), made with [BlueBuild](https://blue-build.org/)

## notes
- turn **secure boot off** before installing, custom akmod modules aren't signed with fedora's keys
- 470xx only goes up to vulkan 1.2 so newer proton/dxvk 2.x can crash. grab **Proton Sarek** in ProtonPlus or use `PROTON_USE_WINED3D=1 %command%` in steam launch options
- once he upgrades to a newer gpu (like a gtx 1060 or rtx/amd card), run `ujust upgrade-to-bazzite` (or `blujust upgrade-to-bazzite`) to rebase onto bazzite

## iso
```bash
sudo bluebuild generate-iso --iso-name jouer.iso image ghcr.io/fuwaflow/jouer:latest
```
