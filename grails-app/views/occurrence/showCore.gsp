<%--
  Created by IntelliJ IDEA.
  User: dos009@csiro.au
  Date: 19/02/2014
  Time: 4:09 PM
  To change this template use File | Settings | File Templates.
--%>
<%@ page contentType="text/html;charset=UTF-8" %>
<g:set var="recordId" value="${alatag.getRecordId(record: record)}"/>
<g:set var="bieWebappContext" value="${grailsApplication.config.bie.baseURL}"/>
<g:set var="collectionsWebappContext" value="${grailsApplication.config.collections.baseUrl}"/>
<g:set var="useAla" value="${grailsApplication.config.useAla}"/>
<g:set var="hubDisplayName" value="${grailsApplication.config.site.displayName}"/>
<g:set var="biocacheService" value="${grailsApplication.config.biocacheServicesUrl}"/>
<g:set var="scientificName" value="${alatag.getScientificName(record: record)}"/>
<!DOCTYPE html>
<html>
<head>
    <title></title>
</head>

<body>

</body>
</html>