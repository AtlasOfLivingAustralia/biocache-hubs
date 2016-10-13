<%@ page contentType="text/html;charset=UTF-8" %>

<style type="text/css">
    #charts h3 { font-size: 16px; }
    #charts .chart-legend { max-height: 250px; overflow-y: scroll; }
    #charts { margin-top:30px; padding-top:20px; }
    .chart { width:45%;  margin-bottom: 20px; float:left; padding-right: 10px; }
</style>

<r:script>
    <charts:biocache
            biocacheServiceUrl="${alatag.getBiocacheAjaxUrl()}"
            biocacheWebappUrl="${grailsApplication.config.serverName}${request.contextPath}"
            q="${searchString.replace('?q=','')}"
            qc=""
            fq=""
            autoLoad="false"
    />
    <charts:biocache
            biocacheServiceUrl="${alatag.getBiocacheAjaxUrl()}"
            biocacheWebappUrl="${grailsApplication.config.serverName}${request.contextPath}"
            q="${searchString.replace('?q=','')}"
            qc=""
            fq=""
            autoLoad="false"
            chartControls="true"
            chartVariableName="userChartConfig"
    />
</r:script>

<div class="row-fluid" style="padding: 10px; background-color: lightgoldenrodyellow">
    <div id="userCharts"></div>
</div>
<div class="row-fluid">
    <div id="charts"></div>
</div>

