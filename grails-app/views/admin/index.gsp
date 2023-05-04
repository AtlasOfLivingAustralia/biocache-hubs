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
    <meta name="layout" content="${grailsApplication.config.getProperty('skin.name')}"/>
    <title>Admin Functions | ${grailsApplication.config.getProperty('skin.orgNameLong')}</title>
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
                <b><g:message code="home.index.body.alert" default="Alert:"/></b> <alatag:stripApiKey message="${flash.message}"/>
            </div>
        </g:if>
        <div class="panel-heading">
            <h3>Cache management</h3>
        </div>
        <div class="btn-group panel-body">
            <a href="${g.createLink(action:'clearAllCaches')}" class="btn btn-primary ">Clear all caches</a>
            <a href="${g.createLink(action:'clearCollectoryCache')}" class="btn btn-default">Clear collectory cache</a>
            <a href="${g.createLink(action:'clearFacetsCache')}" class="btn btn-default">Clear facets cache</a>
            <a href="${g.createLink(action:'clearLongTermCache')}" class="btn btn-default">Clear long term cache</a>
            <a href="${g.createLink(action:'clearPropertiesCache')}" class="btn btn-default">Clear i18n messages cache</a>
            <a href="${g.createLink(action:'clearRecordCountCache')}" class="btn btn-default">Clear record count cache</a>
        </div>

        <alatag:ifDataQualityEnabled>
            <div class="panel-heading">
                <h3><g:message code="admin.dataquality.heading" default="Data Quality Filters"/></h3>
            </div>
            <div class="panel-body">
                <g:link url="${grailsApplication.config.getProperty('dataquality.baseUrl')}"><g:message code="admin.dataquality.link.text" default="Data Quality filters admin interface"/></g:link>
            </div>
        </alatag:ifDataQualityEnabled>

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