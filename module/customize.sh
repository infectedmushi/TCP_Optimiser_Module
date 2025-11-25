#!/system/bin/sh

SKIPUNZIP=1

ui_print "- Setting permissions"
set_perm_recursive $MODPATH 0 0 0755 0644
set_perm_recursive $MODPATH/webroot 0 0 0755 0644
set_perm $MODPATH/service.sh 0 0 0755
set_perm $MODPATH/post-fs-data.sh 0 0 0755

ui_print "- Extracting module files"
unzip -o "$ZIPFILE" -x 'META-INF/*' -d $MODPATH >&2

ui_print "- Creating directories"
mkdir -p $MODPATH/webroot/css
mkdir -p $MODPATH/webroot/js
mkdir -p $MODPATH/webroot/pages
mkdir -p $MODPATH/webroot/icons

ui_print "- Copying files"

# Core module files (no app.py)
cp -f $MODPATH/module.prop $MODPATH/
cp -f $MODPATH/service.sh $MODPATH/
cp -f $MODPATH/post-fs-data.sh $MODPATH/
cp -f $MODPATH/system.prop $MODPATH/
cp -f $MODPATH/utils.sh $MODPATH/
cp -f $MODPATH/tcp_optimizer.py $MODPATH/

# Web files
cp -rf $MODPATH/webroot/css/* $MODPATH/webroot/css/ 2>/dev/null
cp -rf $MODPATH/webroot/js/* $MODPATH/webroot/js/ 2>/dev/null
cp -rf $MODPATH/webroot/pages/* $MODPATH/webroot/pages/ 2>/dev/null
cp -rf $MODPATH/webroot/icons/* $MODPATH/webroot/icons/ 2>/dev/null
cp -f $MODPATH/webroot/index.html $MODPATH/webroot/ 2>/dev/null

# Set final permissions
ui_print "- Setting final permissions"
chmod 755 $MODPATH/*.sh
chmod 644 $MODPATH/*.py
chmod 644 $MODPATH/*.prop
chmod 644 $MODPATH/webroot/*.html
chmod 644 $MODPATH/webroot/css/*.css
chmod 644 $MODPATH/webroot/js/*.js
chmod 644 $MODPATH/webroot/pages/*.html
chmod 644 $MODPATH/webroot/icons/*.svg

# Create service log directory
mkdir -p /data/adb/tcp_optimiser

ui_print "- TCP Optimiser with CAKE installation completed"
ui_print "- Web interface: http://localhost:5000"
ui_print "- Version: 2.5 by deepongi"