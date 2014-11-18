<%--
  Created by IntelliJ IDEA.
  User: dos009@csiro.au
  Date: 14/03/2014
  Time: 12:27 PM
  To change this template use File | Settings | File Templates.
--%>

<%@ page contentType="text/html;charset=UTF-8" %>
<!DOCTYPE html>
<html>
<head>
    <meta name="layout" content="${grailsApplication.config.skin.layout}"/>
    <title><g:message code="admin.outagem.title" default="Admin - Outage banner"/></title>
</head>
<body>
<div id="breadcrumb">
    <ol class="breadcrumb">
        <li><a href="${g.createLink(uri:"/")}"><g:message code="admin.outagem.navigator.home" default="Home"/></a> <span class=" icon icon-arrow-right"></span></li>
        <li><a href="${g.createLink(controller: 'admin')}"><g:message code="admin.outagem.navigator.admin" default="Admin"/></a> <span class=" icon icon-arrow-right"></span></li>
        <li class="active"><g:message code="admin.outagem.navigator.ob" default="Outage banner"/></li>
    </ol>
</div>
<div class="row-fluid">
    <h1><g:message code="admin.outagem.aom.title" default="Admin - Outage Message"/></h1>
</div>
<form method="POST" class="form-horizontal">
    <div class="warning">
        <g:if test="${message}">${message}</g:if>
    </div>
    <div class="control-group">
        <label class="control-label" for="message"><g:message code="admin.outagem.form.label01" default="Outage Message"/></label>
        <div class="controls">
            <textarea name="message" id="message" class="span4" rows="4">${outageBanner.message}</textarea>
            <span class="help-inline"><g:message code="admin.outagem.form.span01" default="This text will appear on all pages for the period specified in the date fields below"/></span>
        </div>
    </div>
    <div class="control-group">
        <label class="control-label" for="startDate"><g:message code="admin.outagem.form.label02" default="Start Date"/></label>
        <div class="controls">
            <input type="text" name="startDate" id="startDate" class="span2" value="${outageBanner.startDate}" placeholder=""/>
            <span class="help-inline"><code><g:message code="admin.outagem.form.span02" default="yyyy-mm-dd"/></code> format (optional)</span>
        </div>
    </div>
    <div class="control-group">
        <label class="control-label" for="endDate"><g:message code="admin.outagem.form.label03" default="End Date"/></label>
        <div class="controls">
            <input type="text" name="endDate" id="endDate" class="span2" value="${outageBanner.endDate}" placeholder=""/>
            <span class="help-inline"><code><g:message code="admin.outagem.form.span03" default="yyyy-mm-dd"/></code> format (optional)</span>
        </div>
    </div>
    <div class="control-group">
        <label class="control-label" for="endDate"><g:message code="admin.outagem.form.label04" default="Display message"/></label>
        <div class="controls">
            <input type="checkbox"name="showMessage" id="showMessage" class="span2" ${(true && outageBanner.showMessage)?'checked="checked"':''}/>
            <span class="help-inline"><g:message code="admin.outagem.form.span04" default="check this to show the message"/></span>
        </div>
    </div>
    <div class="control-group">
        <%--<label class="control-label" for="endDate"></label>--%>
        <div class="controls">
            <input type="submit" value=<g:message code="admin.outagem.form.submit" default="Submit"/> class="btn">
        </div>
    </div>
</form>
</body>
</html>