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
    <asset:javascript src="jquery.js" />
    <asset:stylesheet src="admin.css" />
</head>
<body>
<div class="row-fluid">
    <div class="col-md=12">
        <div id="breadcrumb">
            <ol class="breadcrumb">
                <li><a href="${g.createLink(uri:"/")}">Home</a> <span class=" icon icon-arrow-right"></span></li>
                <li class="active">Admin</li>
            </ol>
        </div>

        <h1>Admin Functions</h1>

        <g:if test="${flash.message}">
            <div class="message alert alert-info">
                <button type="button" class="close" onclick="$(this).parent().hide()">×</button>
                <b>Alert:</b> ${raw(flash.message)}
            </div>
        </g:if>

        <h2>Cache management</h2>
        <div class="btn-group">
            <a href="${g.createLink(action:'clearAllCaches')}" class="btn btn-primary ">Clear all caches</a>
            <a href="${g.createLink(action:'clearCollectoryCache')}" class="btn btn-default">Clear collectory cache</a>
            <a href="${g.createLink(action:'clearFacetsCache')}" class="btn btn-default">Clear facets cache</a>
            <a href="${g.createLink(action:'clearLongTermCache')}" class="btn btn-default">Clear long term cache</a>
            <a href="${g.createLink(action:'clearPropertiesCache')}" class="btn btn-default">Clear i18n messages cache</a>
        </div>

        <div id="alaAdmin">
            <hr>
            <g:render template="/ala-admin-form" plugin="ala-admin-plugin"/>
        </div>
    </div>
</div>
<br/>
<br/>
<br/>
</body>
</html>