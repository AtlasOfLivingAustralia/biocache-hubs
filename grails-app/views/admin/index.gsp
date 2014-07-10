<%--
  Created by IntelliJ IDEA.
  User: dos009@csiro.au
  Date: 15/03/2014
  Time: 1:13 PM
  To change this template use File | Settings | File Templates.
--%>

<%@ page contentType="text/html;charset=UTF-8" %>
<!DOCTYPE html>
<html>
<head>
    <meta name="layout" content="${grailsApplication.config.skin.layout}"/>
    <title>Admin Functions | ${grailsApplication.config.skin.orgNameLong}</title>
    <r:require modules="jquery"/>
</head>
<body>
<div id="breadcrumb">
    <ol class="breadcrumb">
        <li><a href="${g.createLink(uri:"/")}">Home</a> <span class=" icon icon-arrow-right"></span></li>
        <li class="active">Admin</li>
    </ol>
</div>
<div class="row-fluid">
    <h1>Admin Functions</h1>
</div>
<g:if test="${flash.message}">
    <div class="message alert alert-info">
        <button type="button" class="close" onclick="$(this).parent().hide()">×</button>
        <b>Alert:</b> ${raw(flash.message)}
    </div>
</g:if>
<div class="row-fluid">
    <h2>Outage banner</h2>
    <div class="offset1 span10">
        <a href="${g.createLink(action:'outageMessage')}" class="btn">Set or modify outage message banner</a>
    </div>
</div>
<div class="row-fluid">
    <h2>External Configuration</h2>
    <div class="offset1 span10">
        <form action="${g.createLink(action:'reloadConfig')}">
            <input type="submit" class="btn" value="Reload config file"/>
            Enter config var/s to check (comma separated): <input type="text" name="configVar" value="${params.configVar?:'default_config'}"/>
            <br/>
            Note: CAS config settings will not be reloaded (only Grails settings)
        </form>
    </div>
    <g:if test="${config}">
        <div class="offset1 span10" style="margin-top:10px;">
            ${raw(config)}
        </div>
    </g:if>
</div>
<div class="row-fluid">
    <h2>Cache management</h2>
    <div class="offset1 span10 ">
        <div class="btn-group">
            <a href="${g.createLink(action:'clearAllCaches')}" class="btn btn-primary ">Clear all caches</a>
            <a href="${g.createLink(action:'clearCollectoryCache')}" class="btn">Clear collectory cache</a>
            <a href="${g.createLink(action:'clearFacetsCache')}" class="btn">Clear facets cache</a>
            <a href="${g.createLink(action:'clearLongTermCache')}" class="btn">Clear long term cache</a>
        </div>
    </div>
</div>
<br/>
<br/>
<br/>
</body>
</html>