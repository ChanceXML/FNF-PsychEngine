package android.permissions;

import haxe.xml.Access;
import openfl.Assets;

#if android
import android.Permissions;
import android.os.Build;
#end

class PermissionManager {
    
    /**
     * Reads an XML file and requests the specified Android permissions via native popups.
     */
    public static function requestFromXML(xmlPath:String):Void {
        #if android
        try {
            // Read the XML file content
            var xmlContent:String = Assets.getText(xmlPath);
            if (xmlContent == null) {
                trace("XML file not found at: " + xmlPath);
                return;
            }

            // Parse the XML
            var xml = Xml.parse(xmlContent);
            var root = new Access(xml.firstElement());

            var permissionsToRequest:Array<String> = [];

            // Extract the permission names
            for (node in root.nodes.resolve("android-permission")) {
                if (node.has.name) {
                    permissionsToRequest.push(node.att.name);
                }
            }

            // Request each permission using the native Android APIs
            for (permission in permissionsToRequest) {
                trace("Checking permission: " + permission);

                // Check if the permission is already granted
                var grantedPerms = Permissions.getGrantedPermissions();
                if (grantedPerms != null && !grantedPerms.contains(permission)) {
                    
                    // Note on MANAGE_EXTERNAL_STORAGE (Android 11+)
                    if (permission == "android.permission.MANAGE_EXTERNAL_STORAGE" && Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        trace("WARNING: MANAGE_EXTERNAL_STORAGE cannot be requested via standard popup on Android 11+.");
                    }
                    
                    // Trigger the native popup
                    Permissions.requestPermission(permission);
                } else {
                    trace("Permission already granted: " + permission);
                }
            }
        } catch (e:Dynamic) {
            trace("Error parsing or requesting permissions: " + e);
        }
        #else
        trace("Permissions can only be requested natively on Android. Ignoring.");
        #end
    }
}
