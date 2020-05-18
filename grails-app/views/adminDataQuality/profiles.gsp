<%@ page contentType="text/html;charset=UTF-8" %>
<!DOCTYPE html>
<html>
<head>
    <meta name="layout" content="${grailsApplication.config.skin.layout}"/>
    <title>Admin Functions | ${grailsApplication.config.skin.orgNameLong}</title>
    <asset:javascript src="jquery.js" />
    <asset:javascript src="bootbox/bootbox.min.js" />
    <asset:stylesheet src="admin.css" />
    <style>
    .smallpadding {
        padding-left: 5px;
        padding-right: 5px;
    }
    </style>
</head>
<body>
<div class="row">
    <div class="col-md-12">
        <div id="breadcrumb">
            <ol class="breadcrumb">
                <li><a href="${g.createLink(uri:"/")}">Home</a> <span class=" icon icon-arrow-right"></span></li>
                <li><g:link controller="admin" action="index">Admin</g:link></li>
                <li class="active">Data Quality Profiles</li>
            </ol>
        </div>
    </div>
</div>
%{-- escape from container-fluid --}%
<div class="container">
    <div class="row">
        <div class="col-md-12">
            <h1>Data Quality Profiles</h1>
            <button data-toggle="modal" data-target="#save-profile-modal" class="btn btn-primary"><alatag:message code="add.profile.button" default="Add Profile" /></button>
        </div>
        <div class="col-md-12">
            <table class="table table-bordered table-hover table-striped table-responsive">
                <thead>
                <tr>
                    <th>Id</th>
                    <th>Name</th>
                    <th>short-name</th>
                    <td>enabled</td>
                    <th></th>
                </tr>
                </thead>
                <tbody>
                <g:each in="${qualityProfileInstanceList}" var="profile">
                    <tr>
                        <td>${profile.id}</td>
                        <td><g:link action="filters" id="${profile.id}">${profile.name}</g:link></td>
                        <td>${profile.shortName}</td>
                        <td>
                            <g:form action="enableQualityProfile" useToken="true">
                                <g:hiddenField name="id" value="${profile.id}" />
                                <g:checkBox name="enabled" value="${profile.enabled}" disabled="${profile.isDefault}"  />
                            </g:form>
                        </td>
                        <td>
                            <button data-id="${profile.id}" class="btn btn-default"><i class="fa fa-edit"></i></button>
                            <g:form action="setDefaultProfile" class="form-inline" style="display:inline;" useToken="true">
                                <g:hiddenField name="id" value="${profile.id}" />
                                <button type="submit" class="btn btn-${profile.isDefault ? 'primary' : 'default'} ${profile.isDefault ? ' active' : ''}" aria-pressed="${profile.isDefault}">Default</button>
                            </g:form>
                            <g:form action="deleteQualityProfile" data-confirmation="${profile.categories.size() > 0}" class="form-inline" style="display:inline;" useToken="true">
                                <g:hiddenField name="id" value="${profile.id}" />
                                <button type="submit" class="btn btn-danger" ${profile.isDefault ? 'disabled' : ''}><i class="fa fa-trash"></i></button>
                            </g:form>
                        </td>
                    </tr>
                </g:each>
                </tbody>
            </table>
        </div>
        <div id="save-profile-modal" class="modal fade" tabindex="-1" role="dialog">
            <div class="modal-dialog" role="document">
                <div class="modal-content">
                    <div class="modal-header">
                        <button type="button" class="close" data-dismiss="modal" aria-label="Close"><span aria-hidden="true">&times;</span></button>
                        <h4 class="modal-title"><alatag:message code="profile.modal.title" default="New Profile" /></h4>
                    </div>
                    <div class="modal-body">
                        <g:form name="save-profile-form" action="saveProfile" useToken="true">
                            <g:hiddenField name="id" value="" />
                            <g:hiddenField name="enabled" value="false" />
                            <g:hiddenField name="isDefault" value="false" />
                            <div class="form-group">
                                <label for="name"><alatag:message code="profile.modal.name.label" default="Name" /></label>
                                <input type="text" class="form-control" id="name" name="name" placeholder="Name">
                            </div>
                            <div class="form-group">
                                <label for="shortName"><alatag:message code="profile.modal.shortName.label" default="Short name" /></label>
                                <input type="text" class="form-control" id="shortName" name="shortName" placeholder="short-name">
                                <p class="help-block"><alatag:message code="profile.modal.shortName.help" default="Label used for selecting this profile in URLs and the like.  A single lower case word is preferred." /></p>
                            </div>
                        </g:form>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
                        <button type="submit" form="save-profile-form" class="btn btn-primary">Save changes</button>
                    </div>
                </div><!-- /.modal-content -->
            </div><!-- /.modal-dialog -->
        </div><!-- /.modal -->
    </div>
</div>
<asset:script type="text/javascript">
    $(function() {
        // var saveProfileModal = $('#save-profile-modal');//.on('shown.bs.modal'
        $('input[name=enabled]').on('click', function(e) {
          $(this).closest('form').submit();
        });
        // confirm delete a profile with categories
        $('form[data-confirmation=true]').on('submit', function(e) {
            var $this = $(this);
            if (!confirm("This profile has categories defined.  Are you sure you want to delete it?")) { // TODO bootbox
                e.preventDefault();
                return false;
            }
        });
    });
</asset:script>
</body>
</html>