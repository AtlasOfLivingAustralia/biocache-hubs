<%@ page contentType="text/html;charset=UTF-8" %>
<!DOCTYPE html>
<html>
<head>
    <meta name="layout" content="${grailsApplication.config.skin.layout}"/>
    <title>Admin Functions | ${grailsApplication.config.skin.orgNameLong}</title>
    <asset:javascript src="jquery.js" />
    <asset:javascript src="bootbox/bootbox.min.js" />
    <asset:stylesheet src="admin.css" />
</head>
<body>
<div class="row">
    <div class="col-md-12">
        <div id="breadcrumb">
            <ol class="breadcrumb">
                <li><a href="${g.createLink(uri:"/")}">Home</a> <span class=" icon icon-arrow-right"></span></li>
                <li><g:link controller="admin" action="index">Admin</g:link></li>
                <li class="active">Data Quality Filters</li>
            </ol>
        </div>
    </div>
</div>
%{-- escape from container-fluid --}%
<div class="container">
<div class="row">
    <div class="col-md-12">
        <h1>Data Quality Filters</h1>

        <g:if test="${flash.errors}">
            <div class="alert alert-danger">
                <g:eachError bean="${flash.errors}">
                    <li><g:message error="${it}"/></li>
                </g:eachError>
            </div>
        </g:if>

        <p>
            <button class="btn btn-primary" id="add-category" data-toggle="modal" data-target="#add-category-modal"><i class="fa fa-plus"></i> Add category</button>
        </p>

    </div>
    <div class="col-md-12">
        <g:each in="${qualityCategoryInstanceList}" var="category">
            <div class="panel panel-default">
                <div class="panel-heading">
                    <g:form action="deleteQualityCategory" class="form-inline pull-right" data-confirmation="${category.qualityFilters.size() > 0}"><g:hiddenField name="id" value="${category.id}"/><button type="submit" class="btn btn-xs btn-danger">&times;</button></g:form>
                    <h3 class="panel-title">${category.name} (${category.label}) <button class="btn btn-xs btn-default" disabled><i class="fa fa-edit"></i></button></h3>
                </div>
                <g:if test="${category.description}">
                    <div class="panel-body">
                        <p>${category.description}</p>
                    </div>
                </g:if>
                <ul class="list-group">
                    <g:each in="${category.qualityFilters}" var="filter">
                        <li class="list-group-item">
                            <g:form class="form-inline" action="saveQualityFilter" style="display: inline-block;">
                                <g:hiddenField name="id" value="${filter.id}"/>
                                <g:hiddenField name="qualityCategory" value="${category.id}" />
                                <div class="form-group">
                                    <label for="filter">Description</label>
                                    <g:textField class="form-control" name="description" value="${filter.description}" />
                                </div>

                                <div class="form-group">
                                    <label for="filter">Filter</label>
                                    <g:textField class="form-control" name="filter" value="${filter.filter}" />
                                </div>

                                <button type="button" class="btn btn-sm btn-default btn-encode" title="URI encode">%3A</button>
                                <button type="button" class="btn btn-sm btn-default btn-decode" title="URI decode">:</button>
                                <button type="submit" class="btn btn-sm btn-success"><i class="fa fa-save"></i></button>
                                <button type="reset" class="btn btn-sm btn-default"><i class="fa fa-refresh"></i></button>
                            </g:form>
                            <g:form class="form-inline" action="deleteQualityFilter" style="display: inline-block;">
                                <g:hiddenField name="id" value="${filter.id}"/>
                                <button type="submit" class="btn btn-sm btn-danger"><i class="fa fa-trash"></i></button>
                            </g:form>
                        </li>
                    </g:each>
                    <li class="list-group-item">
                        <g:form class="form-inline" action="saveQualityFilter">
                            <g:hiddenField name="qualityCategory" value="${category.id}" />
                            <div class="form-group">
                                <label for="filter">Description</label>
                                <g:textField class="form-control" name="description" placeholder="Short descriptive text" />
                            </div>
                            <div class="form-group">
                                <label for="filter">Filter</label>
                                <g:textField class="form-control" name="filter" placeholder="some-raw-filter" />
                            </div>
                            <button type="button" class="btn btn-sm btn-default btn-encode" title="URI encode">%3A</button>
                            <button type="button" class="btn btn-sm btn-default btn-decode" title="URI decode">:</button>
                            <button type="submit" class="btn btn-sm btn-success"><i class="fa fa-plus"></i></button>
                        </g:form>
                    </li>
                </ul>
            </div>
        </g:each>

    </div>
</div>
<div id="add-category-modal" class="modal fade" tabindex="-1" role="dialog">
    <div class="modal-dialog" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
                <h4 class="modal-title">New Data Quality Category</h4>
            </div>
            <div class="modal-body">
                <g:form name="add-category-form" action="saveQualityCategory" method="POST">
                    <div class="form-group">
                        <label for="name">Category name</label>
                        <g:textField name="name" placeholder="Outliers" class="form-control" />
                    </div>
                    <div class="form-group">
                        <label for="name">Label</label>
                        <g:textField name="label" placeholder="short-label-for-ui" class="form-control" />
                    </div>
                    <div class="form-group">
                        <label for="description">Category description</label>
                        <g:textArea name="description" placeholder="Lorum ipsum..." class="form-control" />
                    </div>
                </g:form>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
                <button type="button" class="btn btn-primary" id="add-category-save">Save changes</button>
            </div>
        </div><!-- /.modal-content -->
    </div><!-- /.modal-dialog -->
</div><!-- /.modal -->
</div>
</body>
<asset:script type="text/javascript">
    // $('#add-category').on('click', function(e) {
    //     $("#add-category-modal").modal();
    // });
%{--    $('input[type=checkbox][name=raw]').on('change', function(e) {--}%
%{--        var $this = $(this);--}%
%{--        var checked = $this.is(':checked');--}%
%{--        var cls = checked ? '${RawQualityFilter.name}' : '${SimpleQualityFilter.name}';--}%
%{--        $this.next('input[name=class]').val(cls);--}%
%{--        var $form = $this.closest('form');--}%
%{--        $form.find('.new-raw-filter').toggleClass('hidden', !checked);--}%
%{--        $form.find('.new-simple-filter').toggleClass('hidden', checked);--}%
%{--    });--}%
    $('form[data-confirmation=true]').on('submit', function(e) {
        var $this = $(this);
        if (!confirm("This category has filters defined.  Are you sure you want to delete it?")) { // TODO bootbox
            e.preventDefault();
            return false;
        }
    });
    var $categoryForm = $('#add-category-form');
    $('#add-category-save').on('click', function(e) {
       $categoryForm.submit();
    });
    $categoryForm.find('input[name=name]').on('change', function(e) {
        var $label = $categoryForm.find('input[name=label]');
        if (!$label.val()) {
            $label.val($(this).val().toLowerCase().replace(' ', '-'));
        }
    });
    $('.btn-encode').on('click', function(e) {
        var $input = $(this).closest(':has(input[name=filter])').find('input[name=filter]');
        $input.val(encodeURIComponent($input.val()));
    });
    $('.btn-decode').on('click', function(e) {
        var $input = $(this).closest(':has(input[name=filter])').find('input[name=filter]');
        $input.val(decodeURIComponent($input.val()));
    });
</asset:script>
</html>