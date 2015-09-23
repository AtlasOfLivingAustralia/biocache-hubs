<%@ page import="au.org.ala.biocache.hubs.FacetsName; org.apache.commons.lang.StringUtils" contentType="text/html;charset=UTF-8" %>
<form name="advancedSearchForm" id="advancedSearchForm" action="${request.contextPath}/advancedSearch" method="POST">
    <input type="text" id="solrQuery" name="q" style="position:absolute;left:-9999px;" value="${params.q}"/>
    <input type="hidden" name="nameType" value="matched_name_children"/>
    <b><g:message code="advancedsearch.title01" default="Find records that have"/></b>
    <table border="0" width="100" cellspacing="2" class="compact">
        <thead/>
        <tbody>
        <tr>
            <td class="labels"><g:message code="advancedsearch.table01col01.title" default="ALL of these words (full text)"/></td>
            <td>
                <input type="text" name="text" id="text" class="dataset" placeholder="" size="80" value="${params.text}"/>
            </td>
        </tr>
        </tbody>
    </table>
    <b><g:message code="advancedsearch.title02" default="Find records for ANY of the following taxa (matched/processed taxon concepts)"/></b>
    <table border="0" width="100" cellspacing="2" class="compact">
        <thead/>
        <tbody>
        <g:each in="${1..4}" var="i">
            <g:set var="lsidParam" value="lsid_${i}"/>
            <tr style="" id="taxon_row_${i}">
                <td class="labels"><g:message code="advancedsearch.table02col01.title" default="Species/Taxon"/></td>
                <td>
                    <input type="text" value="" id="taxa_${i}" name="taxonText" class="name_autocomplete" size="60">
                    <input type="hidden" name="lsid" class="lsidInput" id="taxa_${i}" value=""/>
                </td>
            </tr>
        </g:each>
        </tbody>
    </table>
    <b><g:message code="advancedsearch.title03" default="Find records that specify the following scientific name (verbatim/unprocessed name)"/></b>
    <table border="0" width="100" cellspacing="2" class="compact">
        <thead/>
        <tbody>
        <tr>
            <td class="labels"><g:message code="advancedsearch.table03col01.title" default="Raw Scientific Name"/></td>
            <td>
                <input type="text" name="raw_taxon_name" id="raw_taxon_name" class="dataset" placeholder="" size="60" value=""/>
            </td>
        </tr>
        </tbody>
    </table>
    <b><g:message code="advancedsearch.title04" default="Find records from the following species group"/></b>
    <table border="0" width="100" cellspacing="2" class="compact">
        <thead/>
        <tbody>
        <tr>
            <td class="labels"><g:message code="advancedsearch.table04col01.title" default="Species Group"/></td>
            <td>
                <select class="species_group" name="species_group" id="species_group">
                    <option value=""><g:message code="advancedsearch.table04col01.option.label" default="-- select a species group --"/></option>
                    <g:each var="group" in="${request.getAttribute("species_group")}">
                        <option value="${group.key}">${group.value}</option>
                    </g:each>
                </select>
            </td>
        </tr>
        </tbody>
    </table>
    <b><g:message code="advancedsearch.title05" default="Find records from the following institution or collection"/></b>
    <table border="0" width="100" cellspacing="2" class="compact">
        <thead/>
        <tbody>
        <tr>
            <td class="labels"><g:message code="advancedsearch.table05col01.title" default="Institution or Collection"/></td>
            <td>
                <select class="institution_uid collection_uid" name="institution_collection" id="institution_collection">
                    <option value=""><g:message code="advancedsearch.table05col01.option01.label" default="-- select an institution or collection --"/></option>
                    <g:each var="inst" in="${request.getAttribute("institution_uid")}">
                        <optgroup label="${inst.value}">
                            <option value="${inst.key}"><g:message code="advancedsearch.table05col01.option02.label" default="All records from"/> ${inst.value}</option>
                            <g:each var="coll" in="${request.getAttribute("collection_uid")}">
                                <g:if test="${inst.key == 'in13' && StringUtils.startsWith(coll.value, inst.value)}">
                                    <option value="${coll.key}">${StringUtils.replace(StringUtils.replace(coll.value, inst.value, ""), " - " ,"")} <g:message code="advancedsearch.table05col01.option03.label" default="Collection"/></option>
                                </g:if>
                                <g:elseif test="${inst.key == 'in6' && StringUtils.startsWith(coll.value, 'Australian National')}">
                                    <%-- <option value="${coll.key}">${fn:replace(coll.value,"Australian National ", "")}</option> --%>
                                    <option value="${coll.key}">${coll.value}</option>
                                </g:elseif>
                                <g:elseif test="${StringUtils.startsWith(coll.value, inst.value)}">
                                    <option value="${coll.key}">${StringUtils.replace(coll.value, inst.value, "")}</option>
                                </g:elseif>
                            </g:each>
                        </optgroup>
                    </g:each>
                </select>
            </td>
        </tr>
        </tbody>
    </table>
    <b><g:message code="advancedsearch.title06" default="Find records from the following regions"/></b>
    <table border="0" width="100" cellspacing="2" class="compact">
        <thead/>
        <tbody>
        <tr>
            <td class="labels"><g:message code="advancedsearch.table06col01.title" default="Country"/></td>
            <td>
                <select class="country" name="country" id="country">
                    <option value=""><g:message code="advancedsearch.table06col01.option.label" default="-- select a country --"/></option>
                    <g:each var="country" in="${request.getAttribute("country")}">
                        <option value="${country.key}">${country.value}</option>
                    </g:each>
                </select>
            </td>
        </tr>
        <tr>
            <td class="labels"><g:message code="advancedsearch.table06col02.title" default="State/Territory"/></td>
            <td>
                <select class="state" name="state" id="state">
                    <option value=""><g:message code="advancedsearch.table06col02.option.label" default="-- select a state/territory --"/></option>
                    <g:each var="state" in="${request.getAttribute("state")}">
                        <option value="${state.key}">${state.value}</option>
                    </g:each>
                </select>
            </td>
        </tr>
        <g:set var="autoPlaceholder" value="start typing and select from the autocomplete drop-down list"/>
        <g:if test="${request.getAttribute("cl1048") && request.getAttribute("cl1048").size() > 1}">
        <tr>
            <td class="labels"><abbr title="Interim Biogeographic Regionalisation of Australia">IBRA</abbr> <g:message code="advancedsearch.table06col03.title" default="region"/></td>
            <td>
                <select class="biogeographic_region" name="ibra" id="ibra">
                    <option value=""><g:message code="advancedsearch.table06col03.option.label" default="-- select an IBRA region --"/></option>
                    <g:each var="region" in="${request.getAttribute("cl1048").sort()}">
                        <option value="${region.key}">${region.value}</option>
                    </g:each>
                </select>
            </td>
        </tr>
        </g:if>
        <g:if test="${request.getAttribute("cl21") && request.getAttribute("cl21").size() > 1}">
        <tr>
            <td class="labels"><abbr title="Integrated Marine and Coastal Regionalisation of Australia">IMCRA</abbr> <g:message code="advancedsearch.table06col04.title" default="region"/></td>
            <td>
                <select class="biogeographic_region" name="imcra" id="imcra">
                    <option value=""><g:message code="advancedsearch.table06col04.option.label" default="-- select an IMCRA region --"/></option>
                    <g:each var="region" in="${request.getAttribute("cl21").sort()}">
                        <option value="${region.key}">${region.value}</option>
                    </g:each>
                </select>
            </td>
        </tr>
        </g:if>
        <g:if test="${request.getAttribute("cl959") && request.getAttribute("cl959").size() > 1}">
        <tr>
            <td class="labels"><g:message code="advancedsearch.table06col05.title" default="Local Govt. Area"/></td>
            <td>
                <select class="lga" name="lga" id="lga">
                    <option value=""><g:message code="advancedsearch.table06col05.option.label" default="-- select local government area--"/></option>
                    <g:each var="region" in="${request.getAttribute("cl959").sort()}">
                        <option value="${region.key}">${region.value}</option>
                    </g:each>
                </select>
            </td>
        </tr>
        </g:if>
        </tbody>
    </table>
    <g:if test="${request.getAttribute("type_status") && request.getAttribute("type_status").size() > 1}">
        <b><g:message code="advancedsearch.title07" default="Find records from the following type status"/></b>
        <table border="0" width="100" cellspacing="2" class="compact">
            <thead/>
            <tbody>
            <tr>
                <td class="labels"><g:message code="advancedsearch.table07col01.title" default="Type Status"/></td>
                <td>
                    <select class="type_status" name="type_status" id="type_status">
                        <option value=""><g:message code="advancedsearch.table07col01.option.label" default="-- select a type status --"/></option>
                        <g:each var="type" in="${request.getAttribute("type_status")}">
                            <option value="${type.key}">${type.value}</option>
                        </g:each>
                    </select>
                </td>
            </tr>
            </tbody>
        </table>
    </g:if>
    <g:if test="${request.getAttribute("basis_of_record") && request.getAttribute("basis_of_record").size() > 1}">
        <b><g:message code="advancedsearch.title08" default="Find records from the following basis of record (record type)"/></b>
        <table border="0" width="100" cellspacing="2" class="compact">
            <thead/>
            <tbody>
            <tr>
                <td class="labels"><g:message code="advancedsearch.table08col01.title" default="Basis of record"/></td>
                <td>
                    <select class="basis_of_record" name="basis_of_record" id="basis_of_record">
                        <option value=""><g:message code="advancedsearch.table08col01.option.label" default="-- select a basis of record --"/></option>
                        <g:each var="bor" in="${request.getAttribute("basis_of_record")}">
                            <option value="${bor.key}"><g:message code="${bor.value}"/></option>
                        </g:each>
                    </select>
                </td>
            </tr>
            </tbody>
        </table>
    </g:if>
    <b><g:message code="advancedsearch.title09" default="Find records with the following dataset fields"/></b>
    <table border="0" width="100" cellspacing="2" class="compact">
        <thead/>
        <tbody>
        <g:if test="${request.getAttribute("data_resource_uid") && request.getAttribute("data_resource_uid").size() > 1}">
            <tr>
                <td class="labels"><g:message code="advancedsearch.dataset.col.label" default="dataset name"/></td>
                <td>
                    <select class="dataset bscombobox" name="dataset" id="dataset">
                        <option value=""></option>
                        <g:each var="region" in="${request.getAttribute("data_resource_uid").sort({it.value})}">
                            <option value="${region.key}">${region.value}</option>
                        </g:each>
                    </select>
                </td>
            </tr>
        </g:if>
        <tr>
            <td class="labels"><g:message code="advancedsearch.table09col01.title" default="Catalogue Number"/></td>
            <td>
                <input type="text" name="catalogue_number" id="catalogue_number" class="dataset" placeholder="" value=""/>
            </td>
        </tr>
        <tr>
            <td class="labels"><g:message code="advancedsearch.table09col02.title" default="Record Number"/></td>
            <td>
                <input type="text" name="record_number" id="record_number" class="dataset" placeholder="" value=""/>
            </td>
        </tr>
        <%--<tr>
            <td class="labels">Collector Name</td>
            <td>
                 <input type="text" name="collector" id="collector" class="dataset" placeholder="" value=""/>
            </td>
        </tr> --%>
        </tbody>
    </table>
    <b><g:message code="advancedsearch.title10" default="Find records within the following date range"/></b>
    <table border="0" width="100" cellspacing="2" class="compact">
        <thead/>
        <tbody>
        <tr>
            <td class="labels"><g:message code="advancedsearch.table10col01.title" default="Begin Date"/></td>
            <td>
                <input type="text" name="start_date" id="startDate" class="occurrence_date" placeholder="" value=""/>
                <g:message code="advancedsearch.table10col01.des" default="(YYYY-MM-DD) leave blank for earliest record date"/>
            </td>
        </tr>
        <tr>
            <td class="labels"><g:message code="advancedsearch.table10col02.title" default="End Date"/></td>
            <td>
                <input type="text" name="end_date" id="endDate" class="occurrence_date" placeholder="" value=""/>
                <g:message code="advancedsearch.table10col02.des" default="(YYYY-MM-DD) leave blank for most recent record date"/>
            </td>
        </tr>
        </tbody>
    </table>
    <input type="submit" value=<g:message code="advancedsearch.button.submit" default="Search"/> class="btn btn-primary" />
    &nbsp;&nbsp;
    <input type="reset" value="Clear all" id="clearAll" class="btn" onclick="$('input#solrQuery').val(''); $('input.clear_taxon').click(); return true;"/>
</form>
<r:script>
    $(document).ready(function() {
        $('.bscombobox').combobox({bsVersion: '2'});
    });

</r:script>