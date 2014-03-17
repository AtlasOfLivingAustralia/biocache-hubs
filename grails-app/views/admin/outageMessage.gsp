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
    <meta name="layout" content="${grailsApplication.config.ala.skin}"/>
    <title>Admin - Outage banner</title>
</head>
<body>
<div id="breadcrumb">
    <ol class="breadcrumb">
        <li><a href="${g.createLink(uri:"/")}">Home</a> <span class=" icon icon-arrow-right"></span></li>
        <li><a href="${g.createLink(controller: 'admin')}">Admin</a> <span class=" icon icon-arrow-right"></span></li>
        <li class="active">Outage banner</li>
    </ol>
</div>
<div class="row-fluid">
    <h1>Admin - Outage Message</h1>
</div>
<form method="POST" class="form-horizontal">
    <div class="warning">
        <g:if test="${message}">${message}</g:if>
    </div>
    <div class="control-group">
        <label class="control-label" for="message">Outage Message</label>
        <div class="controls">
            <textarea name="message" id="message" class="span4" rows="4">${outageBanner.message}</textarea>
            <span class="help-inline">This text will appear on all pages for the<br> period specified in the date fields below</span>
        </div>
    </div>
    <div class="control-group">
        <label class="control-label" for="startDate">Start Date</label>
        <div class="controls">
            <input type="text" name="startDate" id="startDate" class="span2" value="${outageBanner.startDate}"/>
            <span class="help-inline"><code>yyyy-mm-dd</code> format</span>
        </div>
    </div>
    <div class="control-group">
        <label class="control-label" for="endDate">End Date</label>
        <div class="controls">
            <input type="text" name="endDate" id="endDate" class="span2" value="${outageBanner.endDate}"/>
            <span class="help-inline"><code>yyyy-mm-dd</code> format</span>
        </div>
    </div>
    <div class="hide control-group">
        <label class="control-label" for="endDate">Display message</label>
        <div class="controls">
            <input type="checkbox"name="showMessage" id="showMessage" class="span2" ${(true && outageBanner.showMessage)?'checked="checked"':''}/>
            <span class="help-inline">check this to show the message (dates are still required to be valid)</span>
        </div>
    </div>
    <div class="control-group">
        <%--<label class="control-label" for="endDate"></label>--%>
        <div class="controls">
            <input type="submit" value="Submit" class="btn">
        </div>
    </div>
</form>
</body>
</html>