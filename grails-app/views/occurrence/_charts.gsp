<%@ page contentType="text/html;charset=UTF-8" %>

<r:script>
    <charts:biocache
            biocacheServiceUrl="${alatag.getBiocacheAjaxUrl()}"
            biocacheWebappUrl="${grailsApplication.config.serverName}${request.contextPath}"
            q="${searchString.replace('?q=','')}"
            qc=""
            fq=""
            autoLoad="false"
    />
</r:script>

<div class="row-fluid" id="charts">

</div>

