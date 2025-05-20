#!/bin/sh

echo "Reminder that you need Haxe installed for this to work"
echo "Install it using this link if this fails: https://haxe.org/download/version/4.3.6"
echo ""
echo ""
echo "Installing dependencies."

haxelib set lime 8.2.2
haxelib set openfl 9.3.3
haxelib set flixel 5.6.1
haxelib set flixel-addons 3.2.2
haxelib set flixel-ui 2.6.3
haxelib set flixel-tools 1.5.1
haxelib set hscript-iris 1.1.3
haxelib set tjson 1.4.0
haxelib set hxvlc 2.0.1 --skip-dependencies
haxelib git flxanimate https://github.com/ShadowMario/flxanimate dev
haxelib git linc_luajit https://github.com/superpowers04/linc_luajit 1906c4a96f6bb6df66562b3f24c62f4c5bba14a7
haxelib git hxdiscord_rpc https://github.com/MAJigsaw77/hxdiscord_rpc --skip-dependencies

haxelib set flxanimate git
haxelib set linc_luajit git
haxelib set hxdiscord_rpc 1.2.4 --skip-dependencies

echo "Finished!"