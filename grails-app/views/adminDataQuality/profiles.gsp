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
                            <button data-id="${profile.id}" data-name="${profile.name}" data-short-name="${profile.shortName}" data-description="${profile.description}" data-contact-name="${profile.contactName}" data-contact-email="${profile.contactEmail}" data-is-default="${profile.isDefault}" data-enabled="${profile.enabled}" class="btn btn-default btn-edit-profile"><i class="fa fa-edit"></i></button>
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
                            <div class="form-group">
                                <label for="description"><alatag:message code="profile.modal.description.label" default="Description" /></label>
                                <input type="text" class="form-control" id="description" name="description" placeholder="description...">
                            </div>
                            <div class="form-group">
                                <label for="contactName"><alatag:message code="profile.modal.contactName.label" default="Contact Name" /></label>
                                <input type="text" class="form-control" id="contactName" name="contactName" placeholder="Contact Name">
                            </div>
                            <div class="form-group">
                                <label for="contactEmail"><alatag:message code="profile.modal.contactName.label" default="Contact Email (Optional)" /></label>
                                <input type="email" class="form-control" id="contactEmail" name="contactEmail" placeholder="contact.email@example.org">
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
        $('.btn-edit-profile').on('click', function(e) {
            var $this = $(this);
            var id = $this.data('id');
            var name = $this.data('name');
            var shortName = $this.data('short-name');
            var description = $this.data('description');
            var contactName = $this.data('contact-name');
            var contactEmail  = $this.data('contact-email');
            var enabled = $this.data('enabled');
            var isDefault = $this.data('is-default');

            var $saveProfileModal = $('#save-profile-modal');

            var $id = $saveProfileModal.find('input[name=id]');
            var $name = $saveProfileModal.find('input[name=name]');
            var $shortName = $saveProfileModal.find('input[name=shortName]');
            var $description = $saveProfileModal.find('input[name=description]');
            var $contactName = $saveProfileModal.find('input[name=contactName]');
            var $contactEmail = $saveProfileModal.find('input[name=contactEmail]');
            var $enabled = $saveProfileModal.find('input[name=enabled]');
            var $isDefault = $saveProfileModal.find('input[name=isDefault]');

            var oldId = $id.val();
            var oldName = $name.val();
            var oldShortName = $shortName.val();
            var oldDescription = $description.val();
            var oldContactName = $contactName.val();
            var oldContactEmail = $contactEmail.val();
            var oldEnabled = $enabled.val();
            var oldIsDefault = $isDefault.val();

            $id.val(id);
            $name.val(name);
            $shortName.val(shortName);
            $description.val(description);
            $contactName.val(contactName);
            $contactEmail.val(contactEmail);
            $enabled.val(enabled);
            $isDefault.val(isDefault);

            var clearFormFn = function() {
                $id.val(oldId);
                $name.val(oldName);
                $shortName.val(oldShortName);
                $description.val(oldDescription);
                $contactName.val(oldContactName);
                $contactEmail.val(oldContactEmail);
                $enabled.val(oldEnabled);
                $isDefault.val(oldIsDefault);
                $saveProfileModal.off('hidden.bs.modal', clearFormFn);
            };

            $saveProfileModal.modal();

            $saveProfileModal.on('hidden.bs.modal', clearFormFn);
        });
    });
</asset:script>
</body>
</html>