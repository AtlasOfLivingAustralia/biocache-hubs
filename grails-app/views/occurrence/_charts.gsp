<%@ page contentType="text/html;charset=UTF-8" %>

<asset:script type="text/javascript">
    <charts:biocache
            biocacheServiceUrl="${alatag.getBiocacheAjaxUrl()}"
            biocacheWebappUrl="${grailsApplication.config.serverName}${request.contextPath}"
            q="${searchString.replace('?q=','')}"
            qc="${grailsApplication.config.biocache.queryContext ?: ''}"
            fq=""
            autoLoad="false"
    />
</asset:script>

<div id="charts">

</div>
