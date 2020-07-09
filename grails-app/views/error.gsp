<!DOCTYPE html>
<html>
	<head>
		<title><g:if env="development">Grails Runtime Exception</g:if><g:else>Error</g:else></title>
        <meta name="layout" content="${grailsApplication.config.skin.name}"/>
		<g:if env="development"><asset:stylesheet src="errors.css"/></g:if>
	</head>
	<body>
	<h1>
		Application error
	</h1>
	<g:if env="development">
		<ul class="errors">
			<g:if test="${Throwable.isInstance(exception)}">
				<li><g:renderException exception="${exception}" /></li>
			</g:if>
			<g:elseif test="${flash.message}">
				<li>${alatag.stripApiKey(message: flash.message)}</li>
			</g:elseif>
			<g:else>
				<li>An error has occurred</li>
				<li>Exception: ${exception}</li>
				<li>Message: ${message}</li>
				<li>Path: ${path}</li>
			</g:else>
		</ul>
	</g:if>
	<g:else>
		<g:if test="${flash.message}">
			<ul class="errors">
				<li>${alatag.stripApiKey(message: flash.message)}</li>
			</ul>
		</g:if>
	</g:else>
	</body>
</html>
