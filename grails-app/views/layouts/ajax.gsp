<!DOCTYPE html>
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <alatag:addApplicationMetaTags/>
    <title><g:layoutTitle /></title>

    <asset:javascript src="bootstrap/js/bootstrap.js"/>
    <asset:javascript src="hubCore.js"/>

    <asset:stylesheet src="bootstrap/css/bootstrap.css" />
    <asset:stylesheet src="hubCore.css" />

    <g:layoutHead />
</head>
<body class="${pageProperty(name:'body.class')}" id="${pageProperty(name:'body.id')}" onload="${pageProperty(name:'body.onload')}">
<g:layoutBody />
<asset:deferredScripts/>
</body>
</html>