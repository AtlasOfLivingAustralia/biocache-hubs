<%--
  Created by IntelliJ IDEA.
  User: dos009@csiro.au
  Date: 19/02/2014
  Time: 4:09 PM
  To change this template use File | Settings | File Templates.
--%>
<%@ page contentType="text/html;charset=UTF-8" %>
<g:set var="recordId" value="${alatag.getRecordId(record: record)}"/>
<g:set var="bieWebappContext" value="${grailsApplication.config.bie.baseUrl}"/>
<g:set var="collectionsWebappContext" value="${grailsApplication.config.collections.baseUrl}"/>
<g:set var="useAla" value="${grailsApplication.config.skin.useAlaBie?.toBoolean() ? 'true' : 'false'}"/>
<g:set var="taxaLinks" value="${grailsApplication.config.skin.taxaLinks}"/>
<g:set var="hubDisplayName" value="${grailsApplication.config.site.displayName}"/>
<g:set var="biocacheService" value="${alatag.getBiocacheAjaxUrl()}"/>
<g:set var="scientificName" value="${alatag.getScientificName(record: record)}"/>
<!DOCTYPE html>
<html>
<head>
    <meta name="layout" content="ajax"/>
    <title>${recordId} | <g:message code="show.occurrenceRecord" default="Occurrence record"/>  | ${hubDisplayName}</title>
    <script type="text/javascript">
        // Global var OCC_REC to pass GSP data to external JS file
        var OCC_REC = {
            userId: "${userId}",
            userDisplayName: "${userDisplayName}",
            contextPath: "${request.contextPath}",
            recordUuid: "${record.raw.uuid}",
            taxonRank: "${record.processed.classification.taxonRank}",
            taxonConceptID: "${record.processed.classification.taxonConceptID}",
            locale: "${org.springframework.web.servlet.support.RequestContextUtils.getLocale(request)}",
            sensitiveDatasets: {
                <g:each var="sds" in="${sensitiveDatasets}"
                   status="s">'${sds}': '${grailsApplication.config.sensitiveDatasets[sds]}'${s < (sensitiveDatasets.size() - 1) ? ',' : ''}
                </g:each>
            }
        }

    </script>

    <r:require modules="show, amplify, moment"/>
</head>

<body>
<g:render template="recordCore" />
</body>
</html>