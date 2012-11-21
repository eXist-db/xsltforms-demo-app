xquery version "3.0";

import module namespace xdb="http://exist-db.org/xquery/xmldb";

(: The following external variables are set by the repo:deploy function :)

(: file path pointing to the exist installation directory :)
declare variable $home external;
(: path to the directory containing the unpacked .xar package :)
declare variable $dir external;
(: the target collection into which the app is deployed inside /db/apps/ :)
declare variable $target external;

declare variable $db-root := "/db";
declare variable $apps-root := ($db-root || "/" || "apps");

declare variable $xsltforms-collection-name := "xsltforms";
declare variable $xsltforms-collection := ($apps-root || "/" || $xsltforms-collection-name);

declare function local:mkcol-recursive($collection, $components) {
    if (exists($components)) 
    then
        let $newColl := ($collection || "/" || $components[1])
        return (
            xdb:create-collection($collection, $components[1]),
            local:mkcol-recursive($newColl, subsequence($components, 2))
        )
    else
        ()
};

(: Helper function to recursively create a collection hierarchy. :)
declare function local:mkcol($collection, $path) {
    local:mkcol-recursive($collection, tokenize($path, "/"))
};

declare function local:strip-prefix($str as xs:string, $prefix as xs:string) as xs:string? {
    replace($str, $prefix, "")
};

(: store the collection configuration :)
local:mkcol("/db/system/config", $target),
xdb:store-files-from-pattern(("/system/config" || $target), $dir, "*.xconf")