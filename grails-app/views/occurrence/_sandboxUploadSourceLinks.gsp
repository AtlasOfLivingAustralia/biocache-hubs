<g:if test="${grailsApplication.config.sandbox.uploadSource && dataResourceUid && dataResourceUid.startsWith('drt')}">
    <div class="btn-group pull-right">
        <button type="button" class="btn btn-primary dropdown-toggle" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
            <g:message code="list.sandbox.label" /> <span class="caret"></span>
        </button>
        <ul class="dropdown-menu" style="width: initial;">
            <li><a href="${grailsApplication.config.sandbox.uploadSource}/tempDataResource/submitDataForReview?uid=${dataResourceUid}" title="${message(code: 'list.sandbox.submitData.tooltip')}"><g:message code="list.sandbox.submitData.label" /></a></li>
            <li><a href="${grailsApplication.config.sandbox.uploadSource}/tempDataResource/viewMetadata?uid=${dataResourceUid}" title="${message(code: 'list.sandbox.viewMetadata.tooltip')}"><g:message code="list.sandbox.viewMetadata.label" /></a></li>
            <li><a href="${grailsApplication.config.sandbox.uploadSource}/dataCheck/reload?dataResourceUid=${dataResourceUid}" title="${message(code: 'list.sandbox.reloadData.tooltip')}"><g:message code="list.sandbox.reloadData.label" /></a></li>
        </ul>
    </div>
</g:if>