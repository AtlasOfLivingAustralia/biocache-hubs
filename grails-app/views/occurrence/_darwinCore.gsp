%{--
  - Copyright (C) 2016 Atlas of Living Australia
  - All Rights Reserved.
  - The contents of this file are subject to the Mozilla Public
  - License Version 1.1 (the "License"); you may not use this file
  - except in compliance with the License. You may obtain a copy of
  - the License at http://www.mozilla.org/MPL/
  - Software distributed under the License is distributed on an "AS
  - IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
  - implied. See the License for the specific language governing
  - rights and limitations under the License.
  --}%
<g:set var="sections" value="${["Occurrence","Attribution","Identification","Event","Classification","Location","Measurement"]}"/>
<div id="occurrenceDataset" class="hideX">
    <table class="table table-bordered table-striped table-condensed">
        <thead>
            <tr><th width="20%"></th><th width="40%">processed</th><th width="40%">original</th></tr>
        </thead>
        <tbody>
        <g:each in="${sections}" var="section">
            %{--className: ${section.value?.class?.name}<br>--}%
            %{--<g:if test="${section.value instanceof Map}">--}%
            <g:if test="${compareRecord[section]}">
                <tr><td colspan="3" style="padding:10px 5px; font-size:larger;"><b><g:message code="recordcore.section.${section}.title" default="${section}"/></b></td></tr>
                <g:each in="${compareRecord[section]}" var="field">
                    <tr><td>${field.name}</td><td>${field.processed}</td><td>${field.raw}</td></tr>
                </g:each>
            </g:if>

        </g:each>
        </tbody>
    </table>
    %{--${compareRecord}--}%
</div>
<table class="table table-bordered table-striped table-condensed hide">
    <thead>
    <tr>
        <th style="width:15%;"><g:message code="show.processedvsrawview.table.th01" default="Group"/></th>
        <th style="width:15%;"><g:message code="show.processedvsrawview.table.th02" default="Field Name"/></th>
        <th style="width:35%;"><g:message code="show.processedvsrawview.table.th03" default="Original Value"/></th>
        <th style="width:35%;"><g:message code="show.processedvsrawview.table.th04" default="Processed Value"/></th>
    </tr>
    </thead>
    <tbody>
    <alatag:formatRawVsProcessed map="${compareRecord}"/>
    </tbody>
</table>