package android.permissions;

import haxe.xml.Access;
import openfl.Assets;

#if android
import extension.androidtools.Permissions;
import extension.androidtools.os.Build;
#end

class PermissionManager {
    
    public static function requestFromXML(xmlPath:String):Void {
        #if android
        try {
            var xmlContent:String = Assets.getText(xmlPath);
            if (xmlContent == null) {
                return;
            }

            var xml = Xml.parse(xmlContent);
            var root = new Access(xml.firstElement());

            var permissionsToRequest:Array<String> = [];

            for (node in root.nodes.resolve("android-permission")) {
                if (node.has.name) {
                    permissionsToRequest.push(node.att.name);
                }
            }

            var grantedPerms = Permissions.getGrantedPermissions();
            
            for (permission in permissionsToRequest) {
                if (grantedPerms == null || !grantedPerms.contains(permission)) {
                    
                    if (permission == "android.permission.MANAGE_EXTERNAL_STORAGE" && Build.SDK_INT >= 30) {
                        trace("MANAGE_EXTERNAL_STORAGE requires Manual Settings Intent.");
                    }
                    
                    Permissions.requestPermissions([permission]);
                }
            }
        } catch (e:Dynamic) {
            trace("Error: " + e);
        }
        #else
        trace("Android only.");
        #end
    }
}
