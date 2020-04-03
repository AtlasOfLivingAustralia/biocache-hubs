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

        <div class="well">
            <ul>
            <g:each var="qualityFilterString" in="${qualityFilterStrings}">
                <li>${qualityFilterString.key}<code>
                    fq=${qualityFilterString.value}
                </code></li>
            </g:each>
            </ul>
        </div>
        <g:if test="${flash.message}">
            <div class="alert alert-warning">
                <p>${flash.message}</p>
            </div>
        </g:if>
        <g:hasErrors>
            <div class="alert alert-danger">
                <ul>
                    <g:eachError var="error">
                        <li <g:if test="${error in org.springframework.validation.FieldError}">data-field-id="${error.field}"</g:if>><g:message error="${error}"/></li>
                    </g:eachError>
                </ul>
            </div>
        </g:hasErrors>

        <p>
            <button class="btn btn-primary" id="add-category" data-toggle="modal" data-target="#add-category-modal"><i class="fa fa-plus"></i> Add category</button>
        </p>

    </div>
    <div class="col-md-12">
        <g:each in="${qualityCategoryInstanceList}" var="category">
            <div class="panel ${category.enabled ? 'panel-default' : 'panel-warning'} panel-category">
                <div class="panel-heading">
                    <g:form action="deleteQualityCategory" useToken="true" class="form-inline pull-right" data-confirmation="${category.qualityFilters.size() > 0}"><g:hiddenField name="id" value="${category.id}"/><button type="submit" class="btn btn-xs btn-danger">&times;</button></g:form>
                    <h3 class="panel-title">
                        <g:form class="form-inline" style="display: inline-block;" useToken="true" action="enableQualityCategory">
                            <g:hiddenField name="id" value="${category.id}"/>
                            <label class="sr-only">Enabled</label>
                            <g:checkBox name="enabled" value="${category.enabled}" />
                        </g:form>
                        <span class="panel-title-ro">${category.name} (${category.label}) <button class="btn btn-xs btn-default btn-edit-category"><i class="fa fa-edit"></i></button></span>
                        <span class="panel-title-rw hidden">
                            <g:form action="saveQualityCategory" useToken="true" class="form-inline">
                                <g:hiddenField name="id" value="${category.id}"/>
                                <g:hiddenField name="version" value="${category.version}"/>
                                <g:hiddenField name="description" value="${category.description}" />
                                <div class="form-group">
                                    <label for="name">Name</label>
                                    <g:textField class="form-control" name="name" value="${category.name}" />
                                </div>
                                <div class="form-group">
                                    <label for="label">Label</label>
                                    <g:textField class="form-control" name="label" value="${category.label}" />
                                </div>
                                <button type="submit" class="btn btn-sm btn-success"><i class="fa fa-save"></i></button>
                                <button type="reset" class="btn btn-sm btn-default"><i class="fa fa-close"></i></button>
                            </g:form>
                        </span>
                    </h3>
                </div>
                <g:if test="${category.description}">
                    <div class="panel-body">
                        <span class="category-description-ro">
                            <p class="category-description">${category.description}</p>
                            <button class="btn btn-default"><i class="fa fa-edit"></i></button>
                        </span>
                        <span class="category-description-rw hidden">
                            <g:form action="saveQualityCategory" useToken="true">
                                <g:hiddenField name="id" value="${category.id}"/>
                                <g:hiddenField name="version" value="${category.version}"/>
                                <g:hiddenField name="name" value="${category.name}"/>
                                <g:hiddenField name="label" value="${category.label}"/>
                                <g:textArea class="form-control" name="description" value="${category.description}" />
                                <button type="submit" class="btn btn-success"><i class="fa fa-save"></i></button>
                                <button type="reset" class="btn btn-default"><i class="fa fa-close"></i></button>
                            </g:form>
                        </span>
                    </div>
                </g:if>
                <ul class="list-group">
                    <g:each in="${category.qualityFilters}" var="filter">
                        <li class="list-group-item ${!filter.enabled ? 'list-group-item-warning' : '' }">
                            <g:form class="form-inline" style="display: inline-block;" useToken="true" action="enableQualityFilter">
                                <g:hiddenField name="id" value="${filter.id}"/>
                                <label class="sr-only">Enabled</label>
                                <g:checkBox name="enabled" value="${filter.enabled}" />
                            </g:form>
                            <g:form class="form-inline" action="saveQualityFilter" useToken="true" style="display: inline-block;">
                                <g:hiddenField name="id" value="${filter.id}"/>
                                <g:hiddenField name="version" value="${filter.version}"/>
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
                            <g:form class="form-inline" action="deleteQualityFilter" useToken="true" style="display: inline-block;">
                                <g:hiddenField name="id" value="${filter.id}"/>
                                <button type="submit" class="btn btn-sm btn-danger"><i class="fa fa-trash"></i></button>
                            </g:form>
                        </li>
                    </g:each>
                    <li class="list-group-item">
                        <g:form class="form-inline form-new-filter" useToken="true" action="saveQualityFilter">
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
                            <button type="reset" class="btn btn-sm btn-warning hidden"><i class="fa fa-close"></i></button>
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
                <g:form name="add-category-form" useToken="true" action="saveQualityCategory" method="POST">
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
                <button type="button" class="btn btn-primary" id="add-category-save">Save category</button>
            </div>
        </div><!-- /.modal-content -->
    </div><!-- /.modal-dialog -->
</div><!-- /.modal -->
</div>
</body>
<asset:script type="text/javascript">
    // confirm delete a category with filters
    $('form[data-confirmation=true]').on('submit', function(e) {
        var $this = $(this);
        if (!confirm("This category has filters defined.  Are you sure you want to delete it?")) { // TODO bootbox
            e.preventDefault();
            return false;
        }
    });
    // submit add category form using button outside form element
    var $categoryForm = $('#add-category-form');
    $('#add-category-save').on('click', function(e) {
       $categoryForm.submit();
    });
    // default category label
    $categoryForm.find('input[name=name]').on('change', function(e) {
        var $label = $categoryForm.find('input[name=label]');
        if (!$label.val()) {
            $label.val($(this).val().toLowerCase().replace(' ', '-'));
        }
    });
    // URL encoder / decoder
    $('.btn-encode').on('click', function(e) {
        var $input = $(this).closest(':has(input[name=filter])').find('input[name=filter]');
        $input.val(encodeURIComponent($input.val()));
    });
    $('.btn-decode').on('click', function(e) {
        var $input = $(this).closest(':has(input[name=filter])').find('input[name=filter]');
        $input.val(decodeURIComponent($input.val()));
    });
    // Edit category title / label
    $('.panel-title-ro .btn').on('click', function(e) {
        var $this = $(this);
        var $title = $this.closest('.panel-title');
        $title.find('.panel-title-ro').addClass('hidden');
        $title.find('.panel-title-rw').removeClass('hidden');
    });
    // Reset category title / label
    $('.panel-title-rw button[type=reset]').on('click', function(e) {
        var $this = $(this);
        var $title = $this.closest('.panel-title');
        $title.find('.panel-title-ro').removeClass('hidden');
        $title.find('.panel-title-rw').addClass('hidden');
    });
    // Edit category description
    $('.category-description-ro .btn').on('click', function(e) {
        var $this = $(this);
        var $body = $this.closest('.panel-body');
        $body.find('.category-description-ro').addClass('hidden');
        $body.find('.category-description-rw').removeClass('hidden');
    });
    // Reset category description
    $('.category-description-rw button[type=reset]').on('click', function(e) {
        var $this = $(this);
        var $body = $this.closest('.panel-body');
        $body.find('.category-description-ro').removeClass('hidden');
        $body.find('.category-description-rw').addClass('hidden');
    });
    // Any change disables all other controls because this isn't a proper ajax app
    $('input[type=text], textarea').not('#add-category-modal *').on('change input paste', function(e) {
        var $this = $(this);
        var $form = $this.closest('form');
        $('form').not($form).find('button, input[type=button], input[type=text], input[type=checkbox], textarea').prop('disabled', true);
        $('input[type=button], button').not($('form input[type=button], form button')).prop('disabled', true);
    });
    // Resetting form changes then re-enables all previously disabled controls
    $('input[type=reset], button[type=reset]').on('click', function(e) {
        $('form').find('button, input[type=button], input[type=text], input[type=checkbox], textarea').prop('disabled', false);
        $('input[type=button], button').not($('form input[type=button], form button')).prop('disabled', false);
    });
    // New filter form hide the reset button by default
    $('.form-new-filter input[type=text]').on('change', function(e) {
        $(this).closest('form').find('button[type=reset]').removeClass('hidden');
    });
    $('.form-new-filter button[type=reset]').on('click', function(e) {
        $(this).addClass('hidden');
    });
    $('input[type=checkbox][name=enabled]').on('change', function(e) {
        $(this).closest('form').submit();
    });
</asset:script>
</html>