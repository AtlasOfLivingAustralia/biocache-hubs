<!doctype html>
<html>
    <head>
        <title>Page Not Found</title>
        <meta name="layout" content="${grailsApplication.config.getProperty('skin.layout')}">
        <g:if env="development"><asset:stylesheet src="errors.css"/></g:if>
    </head>
    <body>
        <ul class="errors">
            <li>Page not found</li>
            <li>The requested record was not found. The supplied record ID is either incorrect or has been removed or replaced.</li>
        </ul>
    </body>
</html>
