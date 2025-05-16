# Petite Psych

A fork of [Psych Engine](https://github.com/ShadowMario/FNF-PsychEngine) that aims to strip the entirety of base game away from the main engine to make it less much a hassle to mod

---

## Changelog:

- Added Funkin' (0.3+) intro texts
- Removed Psych Engine devs easter egg
- Added "Nigth" easter egg to Title Screen (from Base Game)
- Haxe Library versions are now fixed, please use the setup files inside the setup folder.
- Removed Week-specific Events such as Dadbattle Spotlight, Philly Glow, Kill Henchmen, etc…
- Remove most base game files (aside from the ones that are dependencies)
- Removed Automatic Updater

## Installation:

Refer to [the Build Instructions](./BUILDING.md)

## Customization:

if you wish to disable things like *Lua Scripts* or *Video Cutscenes*, you can read over to `Project.xml`

inside `Project.xml`, you will find several variables to customize Psych Engine to your liking

to start you off, disabling Videos should be simple, simply Delete the line `"VIDEOS_ALLOWED"` or comment it out by wrapping the line in XML-like comments, like this `<!-- YOUR_LINE_HERE -->`

same goes for *Lua Scripts*, comment out or delete the line with `LUA_ALLOWED`, this and other customization options are all available within the `Project.xml` file

## Psych Engine Credits
* Shadow Mario - Programmer
* Riveren - Artist

---

* bbpanzu - Ex-Programmer
* Yoshubs - Ex-Programmer, we do **NOT** condone her doings.
* SqirraRNG - Crash Handler and Base code for Chart Editor's Waveform
* KadeDev - Fixed some cool stuff on Chart Editor and other PRs
* iFlicky - Composer of Psync and Tea Time, also made the Dialogue Sounds
* PolybiusProxy - .MP4 Video Loader Library (hxCodec)
* Keoiki - Note Splash Animations
* Smokey - Sprite Atlas Support
* Nebula the Zorua - some Lua reworks
* superpowers04 - LUA JIT Fork

---
