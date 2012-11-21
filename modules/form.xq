xquery version "1.0";

declare namespace html="http://www.w3.org/1999/xhtml";
declare namespace xf="http://www.w3.org/2002/xforms";

import module namespace config="http://exist-db.org/xquery/apps/config" at "config.xqm";

declare function local:insert-element($node as node()?, $new-node as node(), 
    $element-name-to-check as xs:string, $location as xs:string) { 
        if (local-name($node) eq $element-name-to-check)
        then
            if ($location eq 'before')
            then ($new-node, $node) 
            else 
                if ($location eq 'after')
                then ($node, $new-node)
                else
                    if ($location eq 'first-child')
                    then element { node-name($node) } { 
                        $node/@*
                        ,
                        $new-node
                        ,
                        for $child in $node/node()
                            return 
                                local:insert-element($child, $new-node, $element-name-to-check, $location) 
                    }
                    else
                    if ($location eq 'last-child')
                    then element { node-name($node) } { 
                        $node/@*
                        ,
                        for $child in $node/node()
                            return 
                                local:insert-element($child, $new-node, $element-name-to-check, $location) 
                        ,
                        $new-node
                    }
                    else () (:You remove the $element-to-check if none of the three options are used.:)
        else
            if ($node instance of element()) 
            then
                element { node-name($node) } { 
                    $node/@*
                    , 
                    for $child in $node/node()
                        return 
                            local:insert-element($child, $new-node, $element-name-to-check, $location) 
             }
         else $node
};

let $log := util:log("DEBUG", ("##param-names: ", string-join(request:get-parameter-names(), ' || ')))

let $form-id := request:get-parameter("form-id", "")
(:let $log := util:log("DEBUG", ("##$form-id-form): ", $form-id)):)
let $form := doc(concat($config:app-data, "/", 'examples.xml'))//example[@id eq $form-id]
let $form-name := $form/document-name/text()
(:let $log := util:log("DEBUG", ("##$form-name): ", $form-name)):)
let $form-path := concat($config:app-data, '/', $form-name)
(:let $log := util:log("DEBUG", ("##$form-path): ", $form-path)):)
let $data-file-name := $form/data-file/text()
(:let $log := util:log("DEBUG", ("##$data-file-name): ", $data-file-name)):)
let $data-file-path := concat($config:app-data, '/', $data-file-name)
(:let $log := util:log("DEBUG", ("##$data-file-path): ", $data-file-path)):)
let $form-description := $form/description
(:let $log := util:log("DEBUG", ("##$data-file-path): ", $data-file-path)):)
return
    if ($form-name)
    then 
        let $form-doc := doc($form-path)/html:html
        
        let $css-to-be-added := doc(concat($config:app-data, "/css.xml"))
        (:let $log := util:log("DEBUG", ("##$margin-css): ", $margin-css)):)
        let $form-doc := local:insert-element($form-doc, $css-to-be-added, 'head', 'first-child') 
        (:let $log := util:log("DEBUG", ("##$form-doc2): ", $form-doc)):)
        
        let $eXide-button-data-file-path :=
        if ($data-file-name)
        then
            <div xmlns="http://www.w3.org/1999/xhtml" class="source">
            <div class="toolbar">
                    <a class="btn" href="/exist/apps/eXide/index.html?open={$data-file-path}" target="eXide" data-type="XML"
                        title="Opens the code in eXide in new tab or existing tab if it is already open.">Open data file in eXide</a>
                </div>
            </div>
            else ()
        let $form-doc := 
            if ($data-file-name)
            then
                local:insert-element($form-doc, $eXide-button-data-file-path, 'model', 'after')
            else
                $form-doc

        let $eXide-button-form-path :=
            <div xmlns="http://www.w3.org/1999/xhtml" class="source">
            <div class="toolbar">
                    <a class="btn" href="/exist/apps/eXide/index.html?open={$form-path}" target="eXide" data-type="XML"
                        title="Opens the formin eXide in new tab or existing tab if it is already open.">Open form in eXide</a>
                </div>
            </div>
        let $form-doc := local:insert-element($form-doc, $eXide-button-form-path, 'model', 'after') 
        (:let $log := util:log("DEBUG", ("##$form-doc3): ", $form-doc)):)
        
        let $form-doc := 
            if ($form-description)
            then local:insert-element($form-doc, $form-description, 'body', 'last-child')
            else $form-doc
        
        let $form-doc := local:insert-element($form-doc, $form-description, 'iframe', 'remove')
        
        let $dummy := request:set-attribute("betterform.filter.ignoreResponseBody", "true")
        let $xslt-pi := processing-instruction xml-stylesheet {'type="text/xsl" href="/exist/rest/db/apps/xsltforms/xsltforms.xsl"'}
        let $debug := processing-instruction xsltforms-options {'debug="yes"'}
            return ($xslt-pi, $debug, $form-doc)
    else ()